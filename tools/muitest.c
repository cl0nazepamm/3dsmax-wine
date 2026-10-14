/* muitest: LoadStringW from a (language-neutral) module, e.g. muitest res10.dll 8700 8702 8704 */
#include <windows.h>
#include <stdio.h>

int wmain(int argc, WCHAR **argv)
{
    HMODULE mod;
    if (argc < 3 || !(mod = LoadLibraryExW(argv[1], NULL, 0))) { wprintf(L"load failed %lu\n", GetLastError()); return 1; }
    for (int i = 2; i < argc; i++)
    {
        WCHAR buf[512];
        int len = LoadStringW(mod, _wtoi(argv[i]), buf, ARRAYSIZE(buf));
        wprintf(L"%ls = [%ls] (len %d, err %lu)\n", argv[i], len ? buf : L"", len, len ? 0 : GetLastError());
    }
    return 0;
}
