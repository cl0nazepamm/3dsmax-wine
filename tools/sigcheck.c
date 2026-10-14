/* sigcheck: WinVerifyTrust + signer name for each file argument */
#include <windows.h>
#include <wintrust.h>
#include <softpub.h>
#include <wincrypt.h>
#include <stdio.h>

static void print_signer(const WCHAR *path)
{
    HCERTSTORE store = NULL; HCRYPTMSG msg = NULL; DWORD enc, ct, ft, size = 0;
    if (!CryptQueryObject(CERT_QUERY_OBJECT_FILE, path, CERT_QUERY_CONTENT_FLAG_PKCS7_SIGNED_EMBED,
                          CERT_QUERY_FORMAT_FLAG_BINARY, 0, &enc, &ct, &ft, &store, &msg, NULL))
    { printf("  signer: <none: %lu>\n", GetLastError()); return; }
    CryptMsgGetParam(msg, CMSG_SIGNER_INFO_PARAM, 0, NULL, &size);
    CMSG_SIGNER_INFO *si = malloc(size);
    if (CryptMsgGetParam(msg, CMSG_SIGNER_INFO_PARAM, 0, si, &size))
    {
        CERT_INFO ci = { .Issuer = si->Issuer, .SerialNumber = si->SerialNumber };
        PCCERT_CONTEXT c = CertFindCertificateInStore(store, enc, 0, CERT_FIND_SUBJECT_CERT, &ci, NULL);
        if (c)
        {
            WCHAR name[256], iss[256];
            CertGetNameStringW(c, CERT_NAME_SIMPLE_DISPLAY_TYPE, 0, NULL, name, 256);
            CertGetNameStringW(c, CERT_NAME_SIMPLE_DISPLAY_TYPE, CERT_NAME_ISSUER_FLAG, NULL, iss, 256);
            printf("  signer: %ls  (issuer: %ls)\n", name, iss);
            CertFreeCertificateContext(c);
        }
    }
    free(si); CryptMsgClose(msg); CertCloseStore(store, 0);
}

int wmain(int argc, WCHAR **argv)
{
    GUID action = WINTRUST_ACTION_GENERIC_VERIFY_V2;
    int bad = 0;
    for (int i = 1; i < argc; i++)
    {
        WINTRUST_FILE_INFO fi = { sizeof(fi), argv[i] };
        WINTRUST_DATA wd = { sizeof(wd) };
        wd.dwUIChoice = WTD_UI_NONE; wd.fdwRevocationChecks = WTD_REVOKE_NONE;
        wd.dwUnionChoice = WTD_CHOICE_FILE; wd.pFile = &fi; wd.dwStateAction = WTD_STATEACTION_VERIFY;
        LONG r = WinVerifyTrust(NULL, &action, &wd);
        printf("%s 0x%08lx %ls\n", r == 0 ? "OK  " : "FAIL", (unsigned long)r, argv[i]);
        print_signer(argv[i]);
        wd.dwStateAction = WTD_STATEACTION_CLOSE; WinVerifyTrust(NULL, &action, &wd);
        if (r) bad++;
    }
    return bad;
}
