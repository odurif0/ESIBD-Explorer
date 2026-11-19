/* Test-only stand-in for mscms.dll under Wine 11, which lacks WcsCreateIccProfile (imported by Qt 6.12's
   qwindows.dll). Every function reports that no color profile is available, so Qt falls back to sRGB.
   Loaded only by smoke.sh (WINEDLLOVERRIDES=mscms=n); never part of the executable. */
typedef void *HPROFILE;
typedef int BOOL;
typedef unsigned long DWORD;
__declspec(dllexport) HPROFILE WcsCreateIccProfile(HPROFILE profile, DWORD options) { (void)profile; (void)options; return 0; }
__declspec(dllexport) HPROFILE OpenColorProfileW(void *profile, DWORD access, DWORD share, DWORD creation) { (void)profile; (void)access; (void)share; (void)creation; return 0; }
__declspec(dllexport) BOOL GetColorProfileFromHandle(HPROFILE profile, void *buffer, DWORD *size) { (void)profile; (void)buffer; (void)size; return 0; }
__declspec(dllexport) BOOL CloseColorProfile(HPROFILE profile) { (void)profile; return 1; }
