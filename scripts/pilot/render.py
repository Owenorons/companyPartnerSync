#!/usr/bin/env python3
"""Validate pilot fixtures against repository metadata and render anonymous Apex.
No Salesforce connection or writes. Run with --check to detect stale outputs.
"""
import argparse
import json
from pathlib import Path
import xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[2]
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
PHASES = ['foundation', 'deals', 'leads', 'mdf', 'lifecycle', 'engagement', 'analytics']
STANDARD = {'Account': {'Name'}, 'Contact': {'FirstName','LastName','Email','AccountId'},
            'Opportunity': {'Name','AccountId','StageName','CloseDate','Amount'},
            'Lead': {'FirstName','LastName','Email','Company','Status'}}

def validate(rows):
    seen = set()
    for r in rows:
        assert r['alias'] not in seen, r['alias']
        assert r['phase'] in PHASES
        root = ROOT/'force-app/main/default/objects'/r['object']
        assert root.exists(), r['object']
        assert isinstance(r['key'],str) and (r['key'].startswith('UAT-PILOT-') or r['key'].startswith('uat-pilot-'))
        assert r['fields'][r['keyField']] == r['key']
        for field, value in r['fields'].items():
            if isinstance(value, dict):
                assert len(value)==1, value
                assert next(iter(value)) in {'ref','days','hours','user','leadStatus','opportunityStage'}
                if 'ref' in value:
                    assert value['ref'] in seen, (r['alias'],value)
            if field in STANDARD.get(r['object'], set()): continue
            if field=='Name':
                x=ET.parse(root/(r['object']+'.object-meta.xml'))
                assert x.findtext('m:nameField/m:type',namespaces=NS)=='Text', r['object']
                continue
            p=root/'fields'/(field+'.field-meta.xml')
            assert p.exists(), (r['alias'],field)
            x=ET.parse(p)
            assert x.find('m:formula',NS) is None, (r['alias'],field,'formula')
            typ=x.findtext('m:type',namespaces=NS)
            if field==r['keyField']: assert typ not in {'LongTextArea','AutoNumber'}, (r['alias'],field)
            values=[a.text for a in x.findall('.//m:value/m:fullName',NS)]
            if values and not isinstance(value,dict): assert value in values, (r['alias'],field,value,values)
        seen.add(r['alias'])

def render(rows,phase):
    needed={r['alias'] for r in rows if r['phase']==phase}
    changed=True
    while changed:
        prior=len(needed)
        for r in rows:
            if r['alias'] in needed:
                needed.update(v['ref'] for v in r['fields'].values() if isinstance(v,dict) and 'ref' in v)
        changed=len(needed)!=prior
    selected=[r for r in rows if r['alias'] in needed]
    payload=json.dumps(selected,separators=(',',':')).replace('\\','\\\\').replace("'","\\'")
    template=(ROOT/'scripts/pilot/runner.apex.template').read_text()
    return template.replace('__PHASE__',phase).replace('__PAYLOAD__',payload)

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
    rows=json.loads((ROOT/'scripts/pilot/fixtures.json').read_text());validate(rows)
    for phase in PHASES:
        output=ROOT/'scripts/apex'/('seed-pilot-'+phase+'.apex');content=render(rows,phase)
        if args.check: assert output.exists() and output.read_text()==content, str(output)+' is stale'
        else: output.write_text(content)
    print(f'Validated {len(rows)} fixtures against source schema; {len(PHASES)} phase scripts '+('checked' if args.check else 'rendered'))
if __name__=='__main__': main()
