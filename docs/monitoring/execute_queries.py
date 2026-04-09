import json, subprocess
from datetime import datetime

RG = "rg-cloudshield-prod"
WORKSPACE = "law-cloudshield"

queries = {
    "REQ-01": 'Perf | where Computer in ("vm-web","vm-app") | where CounterName in ("% Processor Time","% Used Memory") | summarize Max=max(CounterValue), Avg=round(avg(CounterValue),2) by Computer, CounterName | order by Computer',
    "REQ-02": 'Syslog | where Computer in ("vm-web","vm-app") | where Facility=="authpriv" | summarize Attempts=count() by Computer',
    "REQ-03": 'Perf | where CounterName=="% Used Space" | summarize MaxDisk=max(CounterValue) by Computer | limit 5',
    "REQ-04": 'AzureActivity | where ResourceGroup=~ "rg-cloudshield-prod" | where OperationNameValue endswith "/write" | summarize Ops=count() by Caller | order by Ops desc | limit 5',
    "REQ-05": 'AzureActivity | where ResourceGroup=~ "rg-cloudshield-prod" | where ActivityStatusValue=="Failed" | summarize Failed=count() by OperationNameValue | limit 5',
    "REQ-06": 'Syslog | where Facility=="authpriv" | where SyslogMessage contains "Accepted" | summarize Logins=count() by Computer | limit 5',
    "REQ-07": 'Perf | where CounterName=="% Processor Time" | summarize CPU=round(avg(CounterValue),2) by Computer | limit 5',
    "REQ-08": 'AzureActivity | where ResourceGroup=~ "rg-cloudshield-prod" | summarize Events=count() by OperationNameValue | order by Events desc | limit 5',
    "REQ-09": 'Perf | summarize Total=count(), Machines=dcount(Computer) | limit 1'
}

print("=" * 60)
print("🔍 EXÉCUTION REQUÊTES KQL [REQ-01] À [REQ-09]")
print("=" * 60)

results = {}
for req, q in queries.items():
    print(f"⏳ {req}...", end=" ", flush=True)
    try:
        cmd = ["az","monitor","log-analytics","query", "--workspace",WORKSPACE, "--resource-group",RG, "--analytics-query",q, "-o","json"]
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
        if r.returncode == 0:
            data = json.loads(r.stdout)
            results[req] = data if isinstance(data, list) else [data]
            print(f"✅ ({len(results[req])} rows)")
        else:
            results[req] = []
            print(f"⚠️")
    except:
        results[req] = []
        print(f"❌")

with open("results.json", "w") as f:
    json.dump(results, f, indent=2, default=str)

print("\n✅ Résultats sauvegardés dans results.json")
