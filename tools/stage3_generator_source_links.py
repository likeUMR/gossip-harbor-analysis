"""Export page-specific recovered source evidence for ordinary HTTP links."""
from pathlib import Path
import posixpath
import re

ROOT=Path(__file__).resolve().parents[1]
DECODED=ROOT/'analysis_data/logic_index/lua/decoded'
STAGE=ROOT/'analysis_output/logic_recovery/stage3'
SOURCES={
 'ItemSpread.lua':STAGE/'Board_Model_Item_ItemSpread.lua',
 'LuckyProduceModel.lua':STAGE/'937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua',
 'ItemFixedSpreadModel.lua':DECODED/'9155738fadf853bcd0d59504afdf21f00caad94271007fe8444d26a64d9bf93a/decompiled.lua',
 'RandomGenerateCodeHelper.lua':DECODED/'f03d9253b57f82e37f0dea724e5603ea3a62cf5fade257eb08fa80c13e0d7570/decompiled.lua',
 'SmartRewardHelper.lua':DECODED/'552b52a4f039d7bcd8c4590854906a4c840bd3a7492fcab4999a597fc475adcd/decompiled.lua',
 'BoardModelHelper.lua':DECODED/'4908a8d707e3b24699810f84db8fa2a299914a0f6e1aa8ee8a13c6f70e49da67/decompiled.lua',
 'GeneratorBoostActivityModel.lua':DECODED/'e153e5646c658a0cfbd2c7ca4bce3a07202bab1ef4e5ef0782585dca7f5e7f01/decompiled.lua',
 'BoostChargeDiscoBoostHandler.lua':DECODED/'0632e1008f11ab0e482f1bcc4ae5f3aa1692ccec150be24f7c53c419d42e1fd8/decompiled.lua',
 'MainBoardModel.lua':DECODED/'c0065dc8ae320f8e49a76b6ab8593622c4cf0c3ff15e58bfe0a58a625636888e/decompiled.lua',
 'BaseBoardModel.lua':DECODED/'014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce/decompiled.lua',
 'PropertyDataManager.lua':DECODED/'85cb427a1f2c143832b99c36dfda5efb0df187f4aa68e1566eabc165ea228160/decompiled.lua',
 'EnergyModel.lua':DECODED/'0030230aa205488a410d3c4ff05d57c69ae5138a92c10ec91f0fe2d31966b7ae/decompiled.lua',
}
for name, module_hash in {
 'ScoreRushModel.lua':'1bba4c2f554d666b8c7dce056d3b0ff65caef30d9365aacbb762d3e208a457fb',
 'TriggerPlaneModel.lua':'38a4598c59738177922821ee5b030d02b2f99139f0f21a8fbb615ac19520a9e9',
 'TriggerBoostModel.lua':'7f763cdc9149705281060b550f02d212ba0c086407c309bf871f6bb4286473e1',
 'TriggerProgressActivityModel.lua':'b930fd4f35600f57f8bebe14a9bf7da7c7e50f3c2143a8108d07e32fe88badfa',
 'HitBricksActivityModel.lua':'283530fbb0d114efdd3466a2e9b53a04d5aaf1498617aa8029fb4a153b1aa4e2',
 'AdventureActivityModel.lua':'1bcaca42aa70f11ce0663f4ee2a4dcee52e5bc5289b76a18723dc9c89517e6af',
 'ItemClickAcquireModule.lua':'9b77d3a2b7d80030bbc961d24980420a21993bc5b3b335648e53c532f9981f4d',
 'CardItemModel.lua':'cc281f0649d072a830a3b132ea60af33f2a2e59f7ffe521cb0ce8cb4bc52c1a6',
 'RoomModel.lua':'363aafacc07b4054b7974bf8d9ef8686fd65a3985b4c74af1febcf29fd556efc',
 'TokenChainActivityModel.lua':'21edf9e951ccd56a5a76abb1e1951565f1a195acf8cdf6e366fbaae2ad1a9861',
 'ActivityModuleManager.lua':'ab366a7559669e33e0e7e315033371a174d1e6f5f551a4d9835b9afe6299a7b9',
 'ConfigModel.lua':'338b600ea574dfe383694802831bb7b0c34cd95f752f9a29b4c5b9fcccc258e8',
 'BootRequire.lua':'e36873cda5eaf1b825bd873a199220a679e29f6697d0d0da1bedab302d6aaae0',
}.items():
    SOURCES[name]=DECODED/module_hash/'decompiled.lua'
PAGES={
 'output/fixed/detail.md':['ItemSpread.lua','ItemFixedSpreadModel.lua','RandomGenerateCodeHelper.lua','BoardModelHelper.lua'],
 'output/chest/detail.md':['ItemSpread.lua','RandomGenerateCodeHelper.lua'],
 'output/smart/detail.md':['ItemSpread.lua','SmartRewardHelper.lua','BoardModelHelper.lua'],
 'overrides/boost/detail.md':['ItemSpread.lua'],
 'overrides/activity/detail.md':['ItemSpread.lua','BoostChargeDiscoBoostHandler.lua'],
 'lifecycle/count/detail.md':['ItemSpread.lua'],
 'lifecycle/cooldown/detail.md':['ItemSpread.lua'],
 'position/auto/detail.md':['ItemSpread.lua'],
 'events/side_effects/detail.md':['GeneratorBoostActivityModel.lua','MainBoardModel.lua'],
 'events/board/detail.md':['BaseBoardModel.lua','MainBoardModel.lua','ItemSpread.lua'],
 'events/resource/detail.md':['PropertyDataManager.lua','EnergyModel.lua','ItemSpread.lua'],
 'lucky/items/smart.md':['LuckyProduceModel.lua'],
 'lucky/items/type.md':['LuckyProduceModel.lua','GeneratorBoostActivityModel.lua'],
 'lucky/free/generate.md':['LuckyProduceModel.lua'],
 'lucky/chance/load.md':['LuckyProduceModel.lua'],
}
PAGES['events/side_effects/detail.md'] += [name for name in SOURCES if name in {
    'ScoreRushModel.lua','TriggerPlaneModel.lua','TriggerBoostModel.lua',
    'TriggerProgressActivityModel.lua','HitBricksActivityModel.lua','AdventureActivityModel.lua',
    'ItemClickAcquireModule.lua','CardItemModel.lua','RoomModel.lua','TokenChainActivityModel.lua','ActivityModuleManager.lua','ConfigModel.lua','BootRequire.lua'}]
PAGES['output/disco/detail.md']=PAGES['overrides/activity/detail.md']
PAGES['output/upgrade/detail.md']=PAGES['overrides/boost/detail.md']
PAGES['output/preparation/detail.md']=['ItemSpread.lua']
PAGES['output/landing/detail.md']=list(dict.fromkeys(PAGES['events/board/detail.md']+PAGES['events/side_effects/detail.md']))
PAGES['energy/consume/detail.md']=PAGES['events/resource/detail.md']

def supplement_source_links(docs):
    target=docs/'assets/recovered-source'
    target.mkdir(exist_ok=True)
    for name,path in SOURCES.items():
        (target/name).write_bytes(path.read_bytes())
    for rel,names in PAGES.items():
        page=docs/'operations/generator'/rel
        if not page.exists():
            continue
        text=page.read_text(encoding='utf-8')
        text=re.sub(r'\n<!-- source-links:start -->.*?<!-- source-links:end -->\n?', '\n',text,flags=re.S)
        if rel in {'output/chest/detail.md','output/smart/detail.md'} and 'class="case-assets"' not in text:
            image=posixpath.relpath('assets/cases/item-204.png',page.parent.relative_to(docs).as_posix())
            text=text.replace('## 贯穿案例：点击食品袋 105\n',
                '## 贯穿案例：点击食品袋 105\n\n'+
                f'<div class="case-assets"><img src="{image}" alt="本页分支对照中实际选中的四级产物204" class="case-icon" style="width:88px;height:88px;object-fit:contain;"></div>\n',1)
        links=[]
        for name in names:
            href=posixpath.relpath('assets/recovered-source/'+name,page.parent.relative_to(docs).as_posix())
            links.append(f'[{name}]({href})')
        addition='\n<!-- source-links:start -->\n\n## 对应源码\n\n'+ ' · '.join(links)+'\n\n<!-- source-links:end -->\n'
        page.write_text(text.rstrip()+ '\n'+addition,encoding='utf-8')
    # These absolute filesystem paths previously produced HTTP 404s in the website.
    replacements={
      'index.md':('Board_Model_Item_ItemSpread.lua','ItemSpread.lua'),
      'lucky/index.md':('937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua','LuckyProduceModel.lua'),
    }
    for rel,(original,name) in replacements.items():
        page=docs/'operations/generator'/rel
        text=page.read_text(encoding='utf-8')
        href=posixpath.relpath('assets/recovered-source/'+name,page.parent.relative_to(docs).as_posix())
        text=text.replace('/C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/'+original,href)
        page.write_text(text,encoding='utf-8')
    # Raw HTML image URLs are not rewritten by MkDocs, unlike Markdown links.
    # Compute them against the rendered URL (leaf pages add one directory).
    for page in (docs/'operations/generator').rglob('*.md'):
        rel=page.relative_to(docs).as_posix()
        rendered_dir=posixpath.dirname(rel) if page.stem=='index' else posixpath.join(posixpath.dirname(rel),page.stem)
        text=page.read_text(encoding='utf-8')
        text=re.sub(r'(\bsrc=")[^"]*assets/cases/([^"]+)(")',
                    lambda m:m[1]+posixpath.relpath('assets/cases/'+m[2],rendered_dir)+m[3],text)
        page.write_text(text,encoding='utf-8')
