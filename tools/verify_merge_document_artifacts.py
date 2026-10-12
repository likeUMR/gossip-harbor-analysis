"""Structural, link and scope preservation checks, separate from semantic gates."""
import hashlib
import json
import re
from urllib.parse import urlsplit,unquote
from bs4 import BeautifulSoup
import yaml
from stage3_merge_documents import SITE, DOCS, BASE, AUDIT


def leaves(value):
    if isinstance(value,str):yield value
    elif isinstance(value,list):
        for v in value:yield from leaves(v)
    elif isinstance(value,dict):
        for v in value.values():yield from leaves(v)


def run():
    config=yaml.safe_load((SITE/'mkdocs.yml').read_text(encoding='utf-8'))
    merge=next(v['棋子拖拽与合成'] for v in config['nav'] if '棋子拖拽与合成' in v)
    nav=list(leaves(merge));expected={p.relative_to(DOCS).as_posix() for p in BASE.rglob('*.md')}
    failures=[];records=[]
    if set(nav)!=expected:failures.append({'type':'nav-scope','missing':sorted(expected-set(nav)),'extra':sorted(set(nav)-expected)})
    if len(nav)!=len(set(nav)):failures.append({'type':'duplicate-nav'})
    for second in merge[1:]:
        children=next(iter(second.values()))
        if not isinstance(children[0],str) or not children[0].endswith('/index.md'):failures.append({'type':'missing-stage-page'})
        for third in children[1:]:
            pages=next(iter(third.values()))
            if len(pages)!=2 or not isinstance(pages[0],str) or not pages[0].endswith('/index.md') or not isinstance(pages[1],dict):failures.append({'type':'not-four-level','node':third})
    original=yaml.safe_load((AUDIT/'before/mkdocs.yml').read_text(encoding='utf-8'))
    for label in ['母体点击','订单提交']:
        a=next(v[label] for v in original['nav'] if label in v)
        b=next(v[label] for v in config['nav'] if label in v)
        if a!=b:failures.append({'type':'other-operation-nav-changed','label':label})
    for rel in nav:
        md=DOCS/rel;target=SITE/'site'/md.relative_to(DOCS).parent
        if md.stem!='index':target/=md.stem
        target/='index.html'
        soup=BeautifulSoup(target.read_text(encoding='utf-8'),'html.parser');article=soup.select_one('article')
        if not article or len(article.select('h1'))!=1 or not article.select('p'):failures.append({'type':'unrendered','page':rel});continue
        if len(article.select('h2'))<1 or not any(label in article.get_text() for label in ('贯穿案例','演示案例')):failures.append({'type':'missing-case','page':rel})
        for e in article.select('a[href],img[src]'):
            href=e.get('href') or e.get('src');u=urlsplit(href)
            if u.scheme or u.netloc or not u.path:continue
            local=(SITE/'site'/unquote(u.path).lstrip('/')) if u.path.startswith('/') else target.parent/unquote(u.path)
            if local.is_dir():local/='index.html'
            if not local.exists():failures.append({'type':'broken-asset','page':rel,'target':href})
            if local.suffix=='.html':failures.append({'type':'internal-document-jump','page':rel,'target':href})
        text=md.read_text(encoding='utf-8')
        if text.startswith('```') or '事件与后续影响' in text or '产出改写与安全边界' in text:failures.append({'type':'forbidden-layout','page':rel})
        records.append({'page':rel,'html_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
                        'headings':len(article.select('h2')),'images':len(article.select('img')),
                        'tables':len(article.select('table')),'paragraphs':len(article.select('p'))})
    result={'kind':'structure-and-assets-only','pages':records,'failures':failures,'status':'passed' if not failures else 'failed',
            'limits':'Does not approve G1-G7 semantic or original-runtime gates; browser screenshots tracked separately.'}
    (AUDIT/'site_validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'pages':len(records),'status':result['status'],'failures':failures},ensure_ascii=False))
    if failures:raise SystemExit(1)


if __name__=='__main__':run()
