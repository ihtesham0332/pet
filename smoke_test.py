import urllib.request, json

def t(url, data=None):
    try:
        h = {"X-API-Key": "dev-internal-key", "Content-Type": "application/json"} if "8000" in url else {"Content-Type": "application/json"}
        body = json.dumps(data).encode() if data else None
        r = urllib.request.urlopen(urllib.request.Request(url, data=body, headers=h), timeout=10)
        return r.status, json.loads(r.read())
    except Exception as e:
        return 0, str(e)

tests = [
    ("AI Service", "http://127.0.0.1:8000/", None),
    ("Emergency", "http://127.0.0.1:8000/v1/emergency/check", {"symptoms": ["dog having seizures"], "pet_species": "dog"}),
    ("Backend", "http://127.0.0.1:8001/", None),
    ("Health", "http://127.0.0.1:8001/health", None),
]

for name, url, data in tests:
    s, d = t(url, data)
    icon = "[OK]" if s == 200 else "[FAIL]"
    print(f"  {icon} {name}: HTTP {s}")
