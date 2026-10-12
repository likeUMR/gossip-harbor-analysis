"""Validate built document targets and rendering structure, not semantic coverage."""
from pathlib import Path
from urllib.parse import urlsplit, unquote
import hashlib
import json
from bs4 import BeautifulSoup

ROOT=Path(__file__).resolve().parents[1]
SITE=ROOT/'analysis_output/logic_recovery/stage3/mkdocs_site'
OUT=ROOT/'analysis_output/logic_recovery/stage3/generator_gate_audit'

def main():
    records=[]
    failures=[]
    for source in sorted((SITE/'docs/operations/generator').rglob('*.md')):
        rel=source.relative_to(SITE/'docs')
        target=SITE/'site'/rel.parent/(rel.stem if rel.stem!='index' else '')/'index.html'
        if not target.exists():
            failures.append({'source':str(rel),'error':'Missing built HTML'})
            continue
        soup=BeautifulSoup(target.read_text(encoding='utf-8'),'html.parser')
        article=soup.select_one('article')
        if article is None or len(article.select('h1'))!=1:
            failures.append({'source':str(rel),'error':'Missing article or single top heading'})
            continue
        broken=[]
        for element in article.select('a[href], img[src]'):
            href=element.get('href') or element.get('src')
            u=urlsplit(href)
            if u.scheme or u.netloc or not u.path:
                continue
            local=(SITE/'site'/unquote(u.path).lstrip('/')) if u.path.startswith('/') else (target.parent/unquote(u.path))
            if local.is_dir(): local=local/'index.html'
            if not local.exists():
                broken.append(href)
            elif u.fragment and local.suffix=='.html':
                other=BeautifulSoup(local.read_text(encoding='utf-8'),'html.parser')
                if other.find(id=unquote(u.fragment)) is None:
                    broken.append(href+' [missing anchor]')
        if broken: failures.append({'source':str(rel),'error':'Broken article targets','targets':broken})
        if len(article.select('p'))==0 or len(article.select('h2'))==0:
            failures.append({'source':str(rel),'error':'No rendered prose or level-two heading'})
        records.append({'source':rel.as_posix(),'html_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
                        'title':article.h1.get_text(' ',strip=True),'paragraphs':len(article.select('p')),
                        'headings':len(article.select('h2')),'images':len(article.select('img')),
                        'tables':len(article.select('table')),'broken_targets':broken})
    payload={'kind':'built-artifact-structure-check','status':'passed' if not failures else 'failed',
             'pages':records,'failures':failures,'limitations':'Does not validate semantic completeness, active browser state, original-client behavior, or rendering at all viewports.'}
    (OUT/'site_validation.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'pages':len(records),'status':payload['status'],'failures':failures},ensure_ascii=False))
    if failures: raise SystemExit(1)

if __name__=='__main__': main()
