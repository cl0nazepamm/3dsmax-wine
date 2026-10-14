/* winlist: list top-level windows (x11 id, pid, visibility, rect, class, title)
 *   winlist all            include hidden windows
 *   winlist tree           visible top-level windows with their child window trees
 *   winlist click H X Y    left-click window H (hex) at client coords X,Y
 *   winlist show|hide H... ShowWindowAsync(SW_SHOWNA / SW_HIDE) on windows (hex handles) */
#include <windows.h>
#include <stdio.h>

static BOOL CALLBACK enum_proc(HWND hwnd, LPARAM all);
static int depth;

static BOOL CALLBACK enum_child(HWND hwnd, LPARAM all)
{
    if (GetParent(hwnd) != (HWND)all) return TRUE;  /* direct children only, recurse ourselves */
    depth++;
    enum_proc(hwnd, 2);
    depth--;
    return TRUE;
}

static BOOL CALLBACK enum_proc(HWND hwnd, LPARAM all)
{
    WCHAR title[256], cls[128];
    DWORD pid; RECT r;
    if ((!all || all == 3) && !IsWindowVisible(hwnd)) return TRUE;
    GetWindowThreadProcessId(hwnd, &pid);
    GetWindowTextW(hwnd, title, 256);
    GetClassNameW(hwnd, cls, 128);
    GetWindowRect(hwnd, &r);
    wprintf(L"%*s", depth * 2, L"");
    wprintf(L"%p x11=0x%lx pid=%04lx %s %5ld,%5ld %5ldx%-5ld [%ls] \"%ls\"\n", hwnd,
            (ULONG)(ULONG_PTR)GetPropA(hwnd, "__wine_x11_whole_window"), pid, IsWindowVisible(hwnd) ? L"V" : L"-",
            r.left, r.top, r.right - r.left, r.bottom - r.top, cls, title);
    if (all == 2 || all == 3) EnumChildWindows(hwnd, enum_child, (LPARAM)hwnd);
    return TRUE;
}


/* left-click at client coordinates of a window */
static int click(HWND hwnd, int x, int y)
{
    POINT pt = { x, y };
    INPUT in[2] = {{ INPUT_MOUSE }, { INPUT_MOUSE }};
    ClientToScreen(hwnd, &pt);
    SetForegroundWindow(hwnd);
    SetCursorPos(pt.x, pt.y);
    Sleep(100);
    in[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    in[1].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(2, in, sizeof(INPUT));
    wprintf(L"clicked %p at client %d,%d (screen %ld,%ld)\n", hwnd, x, y, pt.x, pt.y);
    return 0;
}

int wmain(int argc, WCHAR **argv)
{
    if (argc > 2 && (!wcscmp(argv[1], L"show") || !wcscmp(argv[1], L"hide")))
    {
        int cmd = !wcscmp(argv[1], L"show") ? SW_SHOWNA : SW_HIDE;
        for (int i = 2; i < argc; i++)
        {
            HWND hwnd = (HWND)(ULONG_PTR)_wcstoui64(argv[i], NULL, 16);
            wprintf(L"%ls %p -> %d\n", argv[1], hwnd, ShowWindowAsync(hwnd, cmd));
        }
        return 0;
    }
    if (argc > 4 && !wcscmp(argv[1], L"click"))
        return click((HWND)(ULONG_PTR)_wcstoui64(argv[2], NULL, 16), _wtoi(argv[3]), _wtoi(argv[4]));
    if (argc > 1 && !wcscmp(argv[1], L"tree")) EnumWindows(enum_proc, 3);
    else EnumWindows(enum_proc, argc > 1 && !wcscmp(argv[1], L"all"));
    return 0;
}
