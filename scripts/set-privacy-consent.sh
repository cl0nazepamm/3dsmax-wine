#!/bin/bash
# Record Autodesk desktop privacy preferences for signed-in users so the "Privacy Settings" dialog
# doesn't come up: submitting that dialog under wine ends 3ds Max with exit code 244, the answer is
# never saved (UserConsent/<userId>.json keeps optIn=null, userActionRequired=true) and it asks again.
#   set-privacy-consent.sh [improve=0|1] [offers=0|1]     (default: both off, i.e. all boxes unchecked)
source "$(dirname "$(readlink -f "$0")")/env.sh"
improve=${1:-0}; offers=${2:-0}
python3 -I - "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/Autodesk/ADPSDK/UserConsent" "$improve" "$offers" <<'PY'
import json, os, sys, time
d, improve, offers = sys.argv[1], sys.argv[2] == '1', sys.argv[3] == '1'
want = {'ADSK_PUD_CONTRACTUAL_NECESSITY_DESKTOP': True,       # required, not optional in the dialog
        'ADSK_PUD_OPTIMIZATION_IMPROVEMENT_DESKTOP': improve,  # "Help develop new products and services"
        'ADSK_PUD_GO_TO_MARKET_DESKTOP': offers}              # "Personalize our offers"
now = int(time.time() * 1000)
for f in os.listdir(d) if os.path.isdir(d) else []:
    if not f.endswith('.json') or f in ('en.json', 'en-US.json', 'UnNamed.json'):
        continue
    p = os.path.join(d, f); c = json.load(open(p))
    if 'preferences' not in c:
        continue
    for pref in c['preferences']:
        if pref.get('consentId') in want:
            pref['optIn'] = want[pref['consentId']]; pref['lastUpdated'] = now
    c['userActionRequired'] = False
    json.dump(c, open(p, 'w'), indent=4)
    print(f"recorded consent for {c.get('userId')}")
PY
