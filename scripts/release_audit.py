import json, pathlib, re, sys
ROOT = pathlib.Path(__file__).resolve().parents[1]
errors=[]; warnings=[]

def load_json(path):
    try: return json.loads(path.read_text(encoding='utf-8'))
    except Exception as e: errors.append(f'JSON {path.name}: {e}'); return {}

en=load_json(ROOT/'apple'/'metadata.en-US.json')
fr=load_json(ROOT/'apple'/'metadata.fr-FR.json')
rel=load_json(ROOT/'apple'/'release-config.json')
age=load_json(ROOT/'apple'/'age-rating.json')
for m,label in [(en,'en-US'),(fr,'fr-FR')]:
    for key,limit in [('name',30),('subtitle',30),('promotionalText',170),('keywords',100)]:
        value=m.get(key,'')
        if len(value)>limit: errors.append(f'{label} {key} {len(value)}>{limit}')
    if m.get('bundleId')!='com.operatorx.pullpathar': errors.append(f'{label} bundleId mismatch')
    for key in ('marketingUrl','supportUrl','privacyPolicyUrl','termsUrl'):
        if not str(m.get(key,'')).startswith('https://'): errors.append(f'{label} invalid {key}')
if en.get('name')!=fr.get('name'): warnings.append('localized names differ')
if rel.get('pricing',{}).get('model')!='PAID_UPFRONT': errors.append('pricing model is not PAID_UPFRONT')
if rel.get('pricing',{}).get('advertising') is not False: errors.append('advertising must be false')
if rel.get('privacyAnswer')!='DATA_NOT_COLLECTED': errors.append('privacy answer mismatch')
if age.get('advertising') is not False: errors.append('age rating advertising must be false')
plist=(ROOT/'PullPathAR'/'Resources'/'Info.plist').read_text(encoding='utf-8')
for marker in ('ITSAppUsesNonExemptEncryption','NSCameraUsageDescription'):
    if marker not in plist: errors.append(f'Info.plist missing {marker}')
privacy=(ROOT/'PullPathAR'/'Resources'/'PrivacyInfo.xcprivacy').read_text(encoding='utf-8')
if '<true/>' in privacy and 'NSPrivacyTracking' in privacy: warnings.append('inspect PrivacyInfo: contains true value')
network_markers=('URLSession','Firebase','GoogleMobileAds','GADBanner','Sentry','Amplitude','Mixpanel','Analytics SDK','AdMob')
for p in (ROOT/'PullPathAR').rglob('*.swift'):
    text=p.read_text(encoding='utf-8', errors='ignore')
    for marker in network_markers:
        if marker in text: errors.append(f'privacy/network marker {marker} in {p.relative_to(ROOT)}')
for path in [ROOT/'site'/'index.html',ROOT/'site'/'privacy'/'index.html',ROOT/'site'/'terms'/'index.html',ROOT/'site'/'support'/'index.html',ROOT/'site'/'icon.png',ROOT/'apple'/'REVIEW_NOTES.md',ROOT/'apple'/'APP_PRIVACY_CHECKLIST.md']:
    if not path.exists() or path.stat().st_size==0: errors.append(f'missing/empty {path.relative_to(ROOT)}')
print(f'EN lengths name={len(en.get("name",""))} subtitle={len(en.get("subtitle",""))} promo={len(en.get("promotionalText",""))} keywords={len(en.get("keywords",""))}')
print(f'FR lengths name={len(fr.get("name",""))} subtitle={len(fr.get("subtitle",""))} promo={len(fr.get("promotionalText",""))} keywords={len(fr.get("keywords",""))}')
for w in warnings: print('WARN',w)
if errors:
    for e in errors: print('FAIL',e)
    sys.exit(1)
print('RELEASE_METADATA_AUDIT_PASS')
