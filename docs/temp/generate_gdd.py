# -*- coding: utf-8 -*-
"""
生成游戏设计文档 Word
"""
from docx import Document
from docx.shared import Pt, RGBColor, Inches, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn

doc = Document()

# 设置默认字体
style = doc.styles['Normal']
font = style.font
font.name = '微软雅黑'
font.size = Pt(10.5)
rpr = style.element.get_or_add_rPr()
rfonts = rpr.find(qn('w:rFonts'))
if rfonts is None:
    rfonts = rpr.makeelement(qn('w:rFonts'), {})
    rpr.append(rfonts)
rfonts.set(qn('w:ascii'), '微软雅黑')
rfonts.set(qn('w:hAnsi'), '微软雅黑')
rfonts.set(qn('w:eastAsia'), '微软雅黑')
rfonts.set(qn('w:cs'), '微软雅黑')

# 标题样式 - 清除主题字体引用
for level in range(1, 4):
    hs = doc.styles[f'Heading {level}']
    hs.font.name = '微软雅黑'
    hs.font.color.rgb = RGBColor(0x1A, 0x1A, 0x2E)
    hrpr = hs.element.get_or_add_rPr()
    hrfonts = hrpr.find(qn('w:rFonts'))
    if hrfonts is None:
        hrfonts = hrpr.makeelement(qn('w:rFonts'), {})
        hrpr.append(hrfonts)
    hrfonts.set(qn('w:ascii'), '微软雅黑')
    hrfonts.set(qn('w:hAnsi'), '微软雅黑')
    hrfonts.set(qn('w:eastAsia'), '微软雅黑')
    hrfonts.set(qn('w:cs'), '微软雅黑')
    for attr in [qn('w:asciiTheme'), qn('w:hAnsiTheme'), qn('w:eastAsiaTheme'), qn('w:cstheme')]:
        if hrfonts.get(attr) is not None:
            del hrfonts.attrib[attr]

def add_table(doc, headers, rows, col_widths=None):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = 'Light Grid Accent 1'
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    # 表头
    for i, h in enumerate(headers):
        cell = table.rows[0].cells[i]
        cell.text = h
        for p in cell.paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for r in p.runs:
                r.bold = True
                r.font.size = Pt(9)
    # 数据
    for ri, row in enumerate(rows):
        for ci, val in enumerate(row):
            cell = table.rows[ri + 1].cells[ci]
            cell.text = str(val)
            for p in cell.paragraphs:
                for r in p.runs:
                    r.font.size = Pt(9)
    return table

# ==================== 封面 ====================
title = doc.add_heading('Lab Escape 3D Co-op', level=0)
title.alignment = WD_ALIGN_PARAGRAPH.CENTER
sub = doc.add_paragraph('游戏设计文档（GDD）')
sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
sub.runs[0].font.size = Pt(18)
sub.runs[0].font.color.rgb = RGBColor(0x66, 0x66, 0x66)

doc.add_paragraph()
info = doc.add_paragraph()
info.alignment = WD_ALIGN_PARAGRAPH.CENTER
info.add_run('版本：v1.0\n').font.size = Pt(12)
info.add_run('引擎：Godot 4.7\n').font.size = Pt(12)
info.add_run('类型：3D第一人称多人合作逃生\n').font.size = Pt(12)
info.add_run('日期：2026-09-27').font.size = Pt(12)

doc.add_page_break()

# ==================== 1. 游戏概述 ====================
doc.add_heading('一、游戏概述', level=1)

doc.add_heading('1.1 游戏简介', level=2)
doc.add_paragraph('Lab Escape 3D Co-op 是一款3D第一人称多人合作逃生游戏。玩家从实验室被释放出来，需要逐层探索、完成任务、躲避或击杀怪物，最终逃离设施。游戏强调团队配合、资源管理和紧张的逃生体验。')

doc.add_heading('1.2 核心体验', level=2)
doc.add_paragraph('• 实验室逃出 → 逐层推进 → 合作逃生')
doc.add_paragraph('• 单手持物系统：一次只能拿一个物品，天然产生分工')
doc.add_paragraph('• 背包系统：6格背包（2任务格+4消耗品格），策略性选择携带物品')
doc.add_paragraph('• 职业分工：工程师/医生/侦察兵/突击手，各有专属技能')
doc.add_paragraph('• 动态环境：毒气、低温、黑暗、坍塌等环境危险')
doc.add_paragraph('• 参考作品：BIGWORK后室、逃生试炼（Outlast Trials）、Lethal Company')

doc.add_heading('1.3 核心玩法循环', level=2)
doc.add_paragraph('进入新区域 → 探索/收集道具 → 完成任务（修门/找钥匙/破解终端）→ 防守怪物波次 → 进入中场休息室存档 → 进入下一区域')

# ==================== 2. 道具系统 ====================
doc.add_page_break()
doc.add_heading('二、道具系统', level=1)

doc.add_heading('2.1 道具性质标签说明', level=2)
add_table(doc,
    ['标签', '含义'],
    [
        ['stackable', '可堆叠'],
        ['droppable', '可丢弃（G键）'],
        ['tradeable', '可交易'],
        ['consumable', '使用后消耗'],
        ['holdable', '占用手持槽'],
        ['wearable', '占用穿戴槽'],
        ['placeable', '可放置到地面'],
        ['key_item', '任务物品，不可丢弃'],
        ['battery', '消耗电量'],
        ['ammo_based', '消耗弹药'],
        ['fuel_based', '消耗燃料'],
        ['inventory_task', '背包任务道具（2格）'],
        ['inventory_consumable', '背包消耗品（4格）'],
        ['instant_pickup', '即时拾取（碰到直接生效）'],
    ])

doc.add_heading('2.2 手持工具类（Holdable / Tool）', level=2)
doc.add_paragraph('手持工具占用唯一的手持槽，一次只能拿一个。工具通常不能攻击，但能完成特殊交互。')
add_table(doc,
    ['ID', '名称', '功能', '标签'],
    [
        ['tool_wrench', '扳手', '修理速度+100%，唯一能修门的工具', 'holdable, droppable, tradeable'],
        ['tool_flashlight', '手电筒', '照亮10米范围，电池有限', 'holdable, droppable, tradeable, battery'],
        ['tool_crowbar', '撬棍', '开锁+砸玻璃，近战伤害10', 'holdable, droppable, tradeable'],
        ['tool_fire_extinguisher', '灭火器', '灭火+喷怪减速3秒，容量有限', 'holdable, droppable, fuel_based'],
        ['tool_walkie_talkie', '对讲机', '联机语音沟通', 'holdable, droppable'],
        ['tool_medkit_held', '手持医疗包', '可给队友回血，使用3次', 'holdable, droppable, consumable'],
        ['tool_scanner', '扫描仪', '扫描墙后怪物/道具，电池有限', 'holdable, droppable, battery'],
        ['tool_blowtorch', '焊枪', '切割金属门/修理，燃料有限', 'holdable, droppable, fuel_based'],
        ['tool_keycard', '门禁卡', '开特定门，不可攻击', 'holdable, key_item'],
        ['tool_breakdown', '拆解器', '拆解可动物体获得材料', 'holdable, droppable'],
    ])

doc.add_heading('2.3 手持近战武器（Holdable / Melee）', level=2)
add_table(doc,
    ['ID', '名称', '伤害', '击退', '攻速', '特殊效果', '标签'],
    [
        ['wpn_bat', '木棒', '15', '8', '0.8s', '无', 'holdable, droppable, tradeable'],
        ['wpn_stun_baton', '电击棒', '8', '4', '1.0s', '麻痹2秒，电量有限', 'holdable, droppable, battery'],
        ['wpn_fire_axe', '消防斧', '25', '12', '1.2s', '破甲+砸玻璃', 'holdable, droppable'],
        ['wpn_machete', '砍刀', '18', '7', '0.9s', '出血效果', 'holdable, droppable'],
        ['wpn_hammer', '锤子', '20', '15', '1.5s', '高击退，砸薄弱墙', 'holdable, droppable'],
        ['wpn_pipe', '钢管', '12', '10', '0.8s', '无', 'holdable, droppable'],
        ['wpn_katana', '武士刀', '22', '5', '0.6s', '快速连击', 'holdable, droppable, rare'],
    ])

doc.add_heading('2.4 手持远程武器（Holdable / Ranged）', level=2)
add_table(doc,
    ['ID', '名称', '伤害', '弹匣', '射速', '射程', '特殊', '标签'],
    [
        ['wpn_pistol', '手枪', '25', '12', '0.3s', '50m', '无', 'holdable, droppable, ammo_based'],
        ['wpn_shotgun', '霰弹枪', '8x8', '6', '0.8s', '15m', '近距爆发', 'holdable, droppable, ammo_based'],
        ['wpn_rifle', '步枪', '30', '30', '0.1s', '80m', '全自动', 'holdable, droppable, ammo_based'],
        ['wpn_smg', '冲锋枪', '15', '40', '0.07s', '40m', '高射速', 'holdable, droppable, ammo_based'],
        ['wpn_sniper', '狙击枪', '100', '5', '1.5s', '200m', '爆头秒杀普通怪', 'holdable, droppable, ammo_based, rare'],
        ['wpn_flamethrower', '火焰喷射器', '10/s', '100燃料', '持续', '10m', '灼烧5秒', 'holdable, droppable, fuel_based, rare'],
        ['wpn_grenade_launcher', '榴弹发射器', '80范围', '4', '1.0s', '30m', '范围伤害', 'holdable, droppable, ammo_based, rare'],
    ])

doc.add_heading('2.5 投掷物（Holdable / Throwable）', level=2)
add_table(doc,
    ['ID', '名称', '效果', '标签'],
    [
        ['throw_brick', '砖块', '伤害5+砸晕1秒，引怪', 'holdable, droppable, stackable, consumable'],
        ['throw_bottle', '瓶子', '伤害3+碎裂声引怪', 'holdable, droppable, stackable, consumable'],
        ['throw_molotov', '燃烧瓶', '范围燃烧15/s持续5秒', 'holdable, droppable, stackable, consumable'],
        ['throw_grenade', '手雷', '范围伤害100，3秒引信', 'holdable, droppable, stackable, consumable'],
        ['throw_smoke', '烟雾弹', '烟雾遮挡，怪物失去目标10秒', 'holdable, droppable, stackable, consumable'],
        ['throw_flash', '闪光弹', '致盲怪物3秒', 'holdable, droppable, stackable, consumable'],
        ['throw_decoy', '诱饵器', '发出声音引怪10秒', 'holdable, droppable, stackable, consumable, battery'],
    ])

doc.add_heading('2.6 即时消耗品（Instant Consumable）', level=2)
doc.add_paragraph('碰到直接生效，不进入背包，不占用手持槽。场景中散落放置。')
add_table(doc,
    ['ID', '名称', '效果', '标签'],
    [
        ['con_medkit', '医疗包', '回血30', 'instant_pickup, droppable, tradeable'],
        ['con_large_medkit', '大医疗包', '回血60', 'instant_pickup, droppable, tradeable, rare'],
        ['con_bandage', '绷带', '2秒持续回血15', 'instant_pickup, droppable'],
        ['con_almond_water', '杏仁水', '回血20+解毒', 'instant_pickup, droppable'],
        ['con_adrenaline', '肾上腺素', '移速+50%持续10秒', 'instant_pickup, droppable'],
        ['con_armor_shard', '护甲碎片', '+25护甲', 'instant_pickup, droppable'],
        ['con_battery', '电池', '手电筒/电击棒+50%电量', 'instant_pickup, droppable'],
        ['con_pistol_ammo', '手枪弹药', '+24发', 'instant_pickup, droppable'],
        ['con_shotgun_ammo', '霰弹', '+12发', 'instant_pickup, droppable'],
        ['con_rifle_ammo', '步枪弹', '+60发', 'instant_pickup, droppable'],
        ['con_fuel', '燃料罐', '+100燃料', 'instant_pickup, droppable'],
    ])

doc.add_heading('2.7 穿戴装备（Wearable）', level=2)
doc.add_paragraph('穿戴装备分为头部、身体、脚部三个槽位，穿上后持续生效，视觉上能看出来。')

doc.add_heading('头部槽（Head Slot）', level=3)
add_table(doc,
    ['ID', '名称', '效果', '副作用', '标签'],
    [
        ['wear_gas_mask', '防毒面具', '免疫毒气', '视野-20%', 'wearable, droppable, tradeable'],
        ['wear_night_vision', '夜视仪', '黑暗中可视，绿色滤镜', '电池有限', 'wearable, droppable, tradeable, battery'],
        ['wear_helmet', '头盔', '爆头减伤50%', '无', 'wearable, droppable, tradeable'],
        ['wear_tactical_headset', '战术耳机', '听到更远怪物声音', '无', 'wearable, droppable, tradeable, rare'],
        ['wear_thermal', '热成像仪', '隔墙看到怪物', '电池有限', 'wearable, droppable, tradeable, rare'],
        ['wear_face_mask', '防尘面罩', '少量防毒+防尘', '无', 'wearable, droppable'],
    ])

doc.add_heading('身体槽（Body Slot）', level=3)
add_table(doc,
    ['ID', '名称', '效果', '副作用', '标签'],
    [
        ['wear_hazmat', '防护服', '免疫毒气+腐蚀', '移速-10%', 'wearable, droppable, tradeable'],
        ['wear_winter_suit', '保暖服', '免疫低温掉血', '无', 'wearable, droppable, tradeable'],
        ['wear_bulletproof', '防弹衣', '全局减伤30%', '无', 'wearable, droppable, tradeable'],
        ['wear_tactical_vest', '战术背心', '弹药容量+50%', '无', 'wearable, droppable, tradeable'],
        ['wear_stealth_suit', '潜行服', '怪物探测范围-30%', '无', 'wearable, droppable, tradeable, rare'],
        ['wear_bomb_suit', '防爆服', '爆炸减伤80%', '移速-20%', 'wearable, droppable, tradeable, rare'],
    ])

doc.add_heading('脚部槽（Feet Slot）', level=3)
add_table(doc,
    ['ID', '名称', '效果', '标签'],
    [
        ['wear_grip_boots', '防滑靴', '冰面/湿滑不减速', 'wearable, droppable, tradeable'],
        ['wear_silent_boots', '静音靴', '走路无声，怪物更难发现', 'wearable, droppable, tradeable'],
        ['wear_speed_boots', '加速靴', '移速+15%', 'wearable, droppable, tradeable, rare'],
    ])

doc.add_heading('2.8 放置物（Placeable）', level=2)
add_table(doc,
    ['ID', '名称', '效果', '持续时间', '标签'],
    [
        ['place_turret', '自动炮塔', '自动攻击怪物，伤害10/发，弹药100', '30秒', 'placeable, droppable, tradeable, rare'],
        ['place_electric_trap', '电击陷阱', '踩中麻痹3秒+伤害20', '触发后消失', 'placeable, droppable, tradeable'],
        ['place_spike_trap', '地刺陷阱', '踩中伤害30+减速', '触发后消失', 'placeable, droppable, tradeable'],
        ['place_barricade', '路障', '挡住通道，怪物需打破', '可被打破', 'placeable, droppable, tradeable'],
        ['place_shield_gen', '护盾发生器', '范围内玩家减伤50%', '20秒', 'placeable, droppable, rare'],
        ['place_glow_stick', '照明棒', '照亮10米范围', '60秒', 'placeable, droppable, stackable, tradeable'],
        ['place_med_station', '医疗站', '站里面持续回血5/秒', '15秒', 'placeable, droppable, rare'],
        ['place_ammo_crate', '弹药箱', '站里面补弹药', '15秒', 'placeable, droppable'],
        ['place_sound_decoy', '声音诱饵', '发出声音引怪', '10秒', 'placeable, droppable, stackable'],
        ['place_camera', '监控摄像头', '放置后可切换视角查看', '60秒', 'placeable, droppable, rare'],
    ])

# ==================== 3. 背包系统 ====================
doc.add_page_break()
doc.add_heading('三、背包系统设计', level=1)

doc.add_heading('3.1 槽位分配', level=2)
doc.add_paragraph('背包总共6格，分为两类：')
doc.add_paragraph('• 任务道具槽（Task Slots）：2格，专门放门禁卡、钥匙、保险丝等任务推进道具')
doc.add_paragraph('• 消耗品槽（Consumable Slots）：4格，放医疗包、肾上腺素、弹药等可消耗道具，可堆叠')
doc.add_paragraph('• 手持槽（Held Slot）：1格，和背包完全独立，拿武器/工具，一次只能拿一个')

doc.add_heading('3.2 背包道具详细列表', level=2)

doc.add_heading('任务推进道具（2格，inventory_task）', level=3)
doc.add_paragraph('任务道具拾取后自动进入任务槽，不可丢弃，不可消耗，用于开启特定门/机关。按区域管理，进入新区域时旧区域任务道具自动存入休息室储物箱。')
add_table(doc,
    ['ID', '名称', '用途', '标签'],
    [
        ['task_keycard_lab', '实验室门禁卡', '开实验室区域门', 'inventory_task, key_item'],
        ['task_keycard_office', '办公区门禁卡', '开办公区域门', 'inventory_task, key_item'],
        ['task_keycard_industrial', '工业区门禁卡', '开工业区域门', 'inventory_task, key_item'],
        ['task_key_generator', '发电机钥匙', '开发电机房', 'inventory_task, key_item'],
        ['task_fuse', '保险丝', '插入电源插座通电', 'inventory_task, key_item'],
        ['task_code_piece_a', '密码碎片A', '集齐ABC开最终门', 'inventory_task, key_item'],
        ['task_code_piece_b', '密码碎片B', '集齐ABC开最终门', 'inventory_task, key_item'],
        ['task_code_piece_c', '密码碎片C', '集齐ABC开最终门', 'inventory_task, key_item'],
        ['task_elevator_key', '电梯钥匙', '启动电梯', 'inventory_task, key_item'],
        ['task_valve_handle', '阀门把手', '安装到阀门上控制管道', 'inventory_task, key_item'],
    ])

doc.add_heading('背包消耗品（4格，可堆叠，inventory_consumable）', level=3)
doc.add_paragraph('拾取后进入消耗品槽，按数字键1-4使用，使用后消失。同类型可堆叠，占一格显示数量。')
add_table(doc,
    ['ID', '名称', '效果', '最大堆叠', '标签'],
    [
        ['inv_medkit', '医疗包', '回血30', '3', 'inventory_consumable, consumable'],
        ['inv_large_medkit', '大医疗包', '回血60', '2', 'inventory_consumable, consumable, rare'],
        ['inv_bandage', '绷带', '2秒持续回血15', '5', 'inventory_consumable, consumable'],
        ['inv_adrenaline', '肾上腺素', '移速+50%持续10秒', '2', 'inventory_consumable, consumable'],
        ['inv_painkillers', '止痛药', '减伤50%持续10秒', '2', 'inventory_consumable, consumable'],
        ['inv_almond_water', '杏仁水', '回血20+解毒', '3', 'inventory_consumable, consumable'],
        ['inv_armor_shard', '护甲碎片', '+25护甲', '4', 'inventory_consumable, consumable'],
        ['inv_battery', '电池', '手电筒+50%电量', '3', 'inventory_consumable, consumable'],
        ['inv_pistol_ammo', '手枪弹药', '+24发', '5', 'inventory_consumable, consumable'],
        ['inv_shotgun_ammo', '霰弹', '+12发', '3', 'inventory_consumable, consumable'],
        ['inv_rifle_ammo', '步枪弹', '+60发', '3', 'inventory_consumable, consumable'],
        ['inv_molotov', '燃烧瓶', '投掷范围燃烧', '2', 'inventory_consumable, consumable'],
        ['inv_grenade', '手雷', '投掷范围伤害100', '2', 'inventory_consumable, consumable'],
        ['inv_smoke_grenade', '烟雾弹', '投掷制造烟雾', '2', 'inventory_consumable, consumable'],
    ])

doc.add_heading('3.3 拾取规则', level=2)
doc.add_paragraph('1. 碰到即时消耗品（地上的医疗包）→ 直接生效，不进背包')
doc.add_paragraph('2. 按E拾取手持物 → 进入手持槽，自动替换当前手持物（旧的掉地上）')
doc.add_paragraph('3. 按E拾取任务道具 → 自动进入任务槽（有空位才拾取，满了提示”任务栏已满”）')
doc.add_paragraph('4. 按E拾取消耗品 → 自动进入消耗品槽（可堆叠则叠加，满了提示”背包已满”）')
doc.add_paragraph('5. 按G丢弃当前手持物（不影响背包）')
doc.add_paragraph('6. 数字键1-4使用对应消耗品格的物品')

doc.add_heading('3.4 区域道具管理与储物箱', level=2)
doc.add_paragraph('• 每个区域有自己的任务道具，同时需要的任务道具不超过2个')
doc.add_paragraph('• 进入中场休息室时，可将任务道具存入储物箱')
doc.add_paragraph('• 进入新区域时，旧区域任务道具自动存入储物箱')
doc.add_paragraph('• 储物箱无限容量，跨区域共享')
doc.add_paragraph('• 玩家可在休息室从储物箱取回道具')

# ==================== 4. 场景物体分类 ====================
doc.add_page_break()
doc.add_heading('四、场景物体分类', level=1)

doc.add_heading('4.1 静态场景（Static）', level=2)
doc.add_paragraph('不可动、不可交互，纯碰撞和装饰。')
add_table(doc,
    ['ID', '名称', '性质', '标签'],
    [
        ['static_wall', '墙壁', '不可破坏，碰撞', 'static, collision'],
        ['static_floor', '地板', '不可破坏，碰撞', 'static, collision'],
        ['static_ceiling', '天花板', '不可破坏，碰撞', 'static, collision'],
        ['static_pillar', '柱子', '不可破坏，碰撞', 'static, collision'],
        ['static_pipe', '固定管道', '不可破坏，碰撞+装饰', 'static, collision, decor'],
        ['static_unbreakable_glass', '防弹玻璃', '不可破坏，透明，碰撞', 'static, collision, transparent'],
        ['static_furniture', '固定家具', '不可破坏，碰撞+装饰', 'static, collision, decor'],
        ['static_decor', '纯装饰物', '无碰撞，纯视觉', 'static, decor, no_collision'],
    ])

doc.add_heading('4.2 可动物体（Movable）', level=2)
doc.add_paragraph('有物理或动画，可以移动/开关/操作。')
add_table(doc,
    ['ID', '名称', '功能', '标签'],
    [
        ['mov_door', '门', '开/关，可锁', 'movable, openable, lockable, interactable'],
        ['mov_elevator', '升降平台', '上下移动', 'movable, platform, triggered'],
        ['mov_conveyor', '传送带', '持续移动上面物体', 'movable, surface, continuous'],
        ['mov_crane', '起重机', '操作移动重物', 'movable, operable, heavy'],
        ['mov_pushable_box', '可推箱子', '玩家可推动', 'movable, pushable, physics'],
        ['mov_flip_table', '可翻倒桌子', '按E翻倒当掩体', 'movable, interactable, cover'],
        ['mov_valve', '阀门', '旋转控制管道/门', 'movable, interactable, rotary'],
        ['mov_lift', '电梯', '呼叫/乘坐', 'movable, interactable, moving'],
        ['mov_fan', '工业风扇', '吹飞玩家/轻物', 'movable, environmental, force'],
        ['mov_sliding_door', '自动滑门', '靠近自动开', 'movable, automatic, openable'],
        ['mov_drawbridge', '吊桥', '开关控制通道', 'movable, triggered, platform'],
    ])

doc.add_heading('4.3 可交互（Interactable）', level=2)
doc.add_paragraph('按E触发交互。')
add_table(doc,
    ['ID', '名称', '功能', '标签'],
    [
        ['int_repair_point', '修理点', '按住E修理，需工具', 'interactable, hold, repair, progress'],
        ['int_pickup', '拾取物', '按E拾取', 'interactable, instant, pickup'],
        ['int_terminal', '终端', '按E打开破解界面', 'interactable, puzzle, ui'],
        ['int_save_point', '存档点', '按E存档', 'interactable, save'],
        ['int_shop', '商店', '按E交易', 'interactable, trade, ui'],
        ['int_button', '按钮', '按E触发机关', 'interactable, instant, trigger'],
        ['int_switch', '开关', '按E切换状态', 'interactable, toggle, trigger'],
        ['int_keypad', '密码键盘', '输入密码开门', 'interactable, puzzle'],
        ['int_workbench', '工作台', '升级武器/合成', 'interactable, craft, ui'],
        ['int_bed', '病床', '回血+存档', 'interactable, heal, save'],
        ['int_ladder', '梯子', '按E上下', 'interactable, movement'],
        ['int_lever', '拉杆', '拉动触发机关', 'interactable, toggle, trigger'],
        ['int_power_socket', '电源插座', '插入保险丝通电', 'interactable, key_item'],
        ['int_notes', '笔记/文件', '阅读剧情线索', 'interactable, lore, ui'],
    ])

doc.add_heading('4.4 可破坏（Destructible）', level=2)
doc.add_paragraph('攻击/子弹打碎，打碎后有不同效果。')
add_table(doc,
    ['ID', '名称', '打碎后效果', '标签'],
    [
        ['dest_glass_wall', '玻璃墙', '通道打开，可能放怪', 'destructible, transparent, passage'],
        ['dest_glass_jar', '玻璃罐', '掉补给/放出小怪', 'destructible, loot'],
        ['dest_wooden_crate', '木箱', '掉随机补给', 'destructible, loot'],
        ['dest_vent_grate', '通风口栅栏', '进入通风道', 'destructible, passage'],
        ['dest_weak_wall', '薄弱墙', '大攻击打碎，通道打开', 'destructible, passage, heavy'],
        ['dest_explosive_barrel', '爆炸桶', '范围爆炸伤害', 'destructible, explosive, hazard'],
        ['dest_fire_extinguisher', '灭火器罐', '打碎喷白雾减速', 'destructible, environmental'],
        ['dest_pipe_breakable', '破损管道', '打碎喷蒸汽', 'destructible, hazard'],
        ['dest_monitor', '电脑显示器', '打碎，可能掉道具', 'destructible, loot, decor'],
        ['dest_light_bulb', '灯泡', '打碎变暗', 'destructible, light'],
    ])

doc.add_heading('4.5 环境危险（Hazard）', level=2)
doc.add_paragraph('进入造成伤害或状态效果。')
add_table(doc,
    ['ID', '名称', '效果', '标签'],
    [
        ['haz_gas_zone', '毒气区', '进入掉血+中毒，需防毒面具', 'hazard, area, damage, status'],
        ['haz_hot_floor', '高温地面', '站上面持续掉血', 'hazard, surface, damage'],
        ['haz_acid_pool', '腐蚀液', '大量掉血+腐蚀装备', 'hazard, area, damage'],
        ['haz_electric', '高压电区', '接触麻痹+伤害', 'hazard, area, damage, stun'],
        ['haz_steam_pipe', '蒸汽管', '周期性喷蒸汽伤害', 'hazard, periodic, damage'],
        ['haz_cold_zone', '低温区', '持续掉血+减速，需保暖服', 'hazard, area, damage, status'],
        ['haz_dark_zone', '黑暗区', '视野极差', 'hazard, area, vision'],
        ['haz_collapse_zone', '坍塌区', '周期性掉石头', 'hazard, periodic, damage'],
        ['haz_water', '水域', '移动减速-50%', 'hazard, area, slow'],
        ['haz_fire', '火焰区', '持续掉血+灼烧', 'hazard, area, damage, status'],
        ['haz_quicksand', '流沙', '持续下沉+减速', 'hazard, area, slow'],
        ['haz_laser', '激光栅栏', '接触伤害，可关闭', 'hazard, area, damage, toggleable'],
    ])

# ==================== 5. 怪物系统 ====================
doc.add_page_break()
doc.add_heading('五、怪物系统', level=1)

doc.add_heading('5.1 怪物性质标签', level=2)
add_table(doc,
    ['标签', '含义'],
    [
        ['melee', '近战攻击'],
        ['ranged', '远程攻击'],
        ['chase', '追击型'],
        ['fast', '高速'],
        ['tank', '高血量'],
        ['stealth', '潜行/隐身'],
        ['suicide', '自爆'],
        ['support', '辅助型'],
        ['swarm', '群体出现'],
        ['boss', 'Boss级'],
        ['stationary', '固定位置'],
        ['flying', '飞行'],
        ['poison', '毒属性'],
        ['fire', '火属性'],
        ['armored', '有护甲'],
        ['shield', '有护盾'],
    ])

doc.add_heading('5.2 普通怪（Common）', level=2)
add_table(doc,
    ['ID', '名称', '血量', '伤害', '速度', '机制', '标签'],
    [
        ['mon_chaser', '追击者', '30', '8', '3.0', '基础追击近战', 'melee, chase, common'],
        ['mon_sprinter', '疾行者', '15', '6', '6.0', '高速冲锋', 'melee, fast, chase, common'],
        ['mon_berserker', '狂战士', '80', '15', '2.0', '高伤高血', 'melee, tank, common'],
    ])

doc.add_heading('5.3 远程怪（Ranged）', level=2)
add_table(doc,
    ['ID', '名称', '血量', '伤害', '速度', '机制', '标签'],
    [
        ['mon_acid_spitter', '吐酸怪', '40', '12', '2.0', '远程喷酸液，中毒', 'ranged, poison, uncommon'],
        ['mon_rock_thrower', '投石怪', '50', '10', '1.5', '扔石头', 'ranged, uncommon'],
        ['mon_plasma_shooter', '电浆怪', '35', '18', '2.5', '发射电浆球', 'ranged, rare'],
    ])

doc.add_heading('5.4 特殊怪（Special）', level=2)
add_table(doc,
    ['ID', '名称', '血量', '伤害', '速度', '机制', '标签'],
    [
        ['mon_stalker', '潜行怪', '25', '14', '4.0', '半透明，靠近才显形', 'stealth, melee, rare'],
        ['mon_bomber', '自爆怪', '20', '50范围', '3.5', '靠近后3秒爆炸', 'suicide, explosive, uncommon'],
        ['mon_healer', '治疗怪', '45', '5', '2.0', '给周围怪回血5/秒', 'support, heal, rare'],
        ['mon_splitter', '分裂怪', '60', '10', '2.5', '死后分裂2只小怪', 'split, melee, rare'],
        ['mon_shielder', '护盾怪', '100', '12', '1.8', '正面护盾，需绕后', 'tank, shield, armored, rare'],
        ['mon_summoner', '召唤怪', '70', '8', '1.5', '每5秒召唤1只小怪', 'support, summon, epic'],
        ['mon_controller', '控制怪', '50', '6', '2.0', '远程减速/定身玩家', 'support, cc, rare'],
        ['mon_leaper', '跳跃怪', '30', '16', '3.0', '远距离跳跃扑击', 'melee, fast, uncommon'],
        ['mon_grappler', '抓取怪', '55', '8', '2.2', '抓住玩家拖走', 'melee, cc, rare'],
    ])

doc.add_heading('5.5 环境怪（Environmental）', level=2)
add_table(doc,
    ['ID', '名称', '血量', '伤害', '速度', '机制', '标签'],
    [
        ['mon_leech', '水蛭', '5', '2/秒', '1.0', '附着玩家持续掉血', 'melee, swarm, common'],
        ['mon_spider', '蜘蛛群', '8', '3', '4.0', '大量出现', 'melee, swarm, common'],
        ['mon_tentacle', '触手', '100', '20', '0', '从墙/地面伸出攻击', 'melee, stationary, rare'],
        ['mon_flying_bug', '飞虫群', '10', '4', '5.0', '飞行，绕头攻击', 'flying, swarm, uncommon'],
    ])

doc.add_heading('5.6 Boss（Boss）', level=2)
add_table(doc,
    ['ID', '名称', '血量', '阶段', '机制', '标签'],
    [
        ['boss_alpha', '实验体Alpha', '500', '3阶段', '阶段1追击，阶段2召唤，阶段3狂暴', 'boss, multi_phase, melee'],
        ['boss_behemoth', '巨兽', '800', '2阶段', '巨型追击+地震攻击+投石', 'boss, chase, giant, ranged'],
        ['boss_broodmother', '母体', '600', '2阶段', '持续产卵孵化小怪+毒雾', 'boss, summon, poison'],
        ['boss_mech_guardian', '机械守卫', '700', '3阶段', '远程射击+导弹+冲撞', 'boss, ranged, melee, armored'],
    ])

# ==================== 6. 管理器架构 ====================
doc.add_page_break()
doc.add_heading('六、管理器架构', level=1)

doc.add_paragraph('游戏采用7个全局单例管理器，各司其职，为后续联机做准备。')

managers = [
    ('LevelManager（关卡管理器）', [
        'load_zone(zone_id) - 加载区域所有资产',
        'unload_zone(zone_id) - 卸载区域',
        'load_level(level_id) - 加载关卡',
        'save_game(slot_id) - 存档',
        'load_game(slot_id) - 读档',
        'enter_safe_room() - 进入中场休息室',
        'get_current_zone() - 获取当前区域',
        'register_zone(zone_data) - 注册区域配置',
    ]),
    ('AssetManager（资产管理器）', [
        'preload_assets(asset_list) - 预加载资产',
        'get_asset(asset_id) - 获取资产',
        'spawn_from_pool(id, pos) - 从对象池生成',
        'return_to_pool(id, inst) - 归还对象池',
        'unload_unused() - 卸载未使用资产',
        'get_memory_usage() - 内存占用统计',
    ]),
    ('ItemManager（道具管理器）', [
        'register_item(item_data) - 注册道具',
        'get_item_data(item_id) - 获取道具数据',
        'spawn_item(item_id, pos) - 生成道具',
        'create_pickup(item_id, pos) - 创建拾取物',
        'drop_loot(loot_table, pos) - 掉落战利品',
        'get_all_items() - 获取所有已注册道具',
    ]),
    ('SpawnManager（刷怪管理器）', [
        'start_wave(wave_id) - 开始波次',
        'spawn_monster(type, pos) - 生成怪物',
        'set_spawn_rate(rate) - 设置刷怪速率',
        'stop_spawning() - 停止刷怪',
        'get_alive_count() - 存活怪物数',
        'register_spawn_point(pos) - 注册刷怪点',
        'set_monster_scale(scale) - 设置怪物属性缩放',
    ]),
    ('UIManager（界面管理器）', [
        'update_health(hp, max) - 血量',
        'update_armor(armor, max) - 护甲',
        'update_held_item(data) - 手持物品',
        'update_ammo(cur, max) - 弹药',
        'update_status_effects([]) - 状态效果图标',
        'update_equipment(slots[]) - 穿戴装备显示',
        'update_inventory(slots[]) - 背包显示',
        'show_interaction_prompt() - 交互提示',
        'show_progress() - 进度条',
        'flash_damage() - 受伤红闪',
        'set_crosshair() - 准心',
        'show_teammate_panel() - 队友状态面板（联机）',
        'show_pause_menu() - 暂停菜单',
        'show_shop(items[]) - 商店界面',
        'show_zone_loading(name) - 区域加载界面',
        'show_toast(msg) - 顶部提示',
        'show_objective(text) - 目标提示',
    ]),
    ('AudioManager（音效管理器）', [
        'play_sfx(id) - 播放2D音效',
        'play_3d_sfx(id, pos) - 播放3D音效',
        'play_music(id) - 播放音乐',
        'stop_music() - 停止音乐',
        'set_volume(type, val) - 设置音量',
        'play_footstep(type) - 脚步声',
    ]),
    ('EquipmentManager（装备管理器，每个玩家独立）', [
        'equip(slot, item_id) - 装备到指定槽',
        'unequip(slot) - 卸下装备',
        'get_equipped(slot) - 获取已装备',
        'add_consumable(id, count) - 添加消耗品',
        'use_consumable(id) - 使用消耗品',
        'get_armor_value() - 总护甲值',
        'get_speed_modifier() - 移速修正',
        'get_damage_resistance(type) - 伤害抗性',
        'has_immunity(status) - 是否免疫某状态',
        'update_visuals() - 同步角色外观',
    ]),
]

for name, methods in managers:
    doc.add_heading(name, level=2)
    for m in methods:
        doc.add_paragraph('• ' + m)

# ==================== 7. 关卡区域设计 ====================
doc.add_page_break()
doc.add_heading('七、关卡区域设计', level=1)

doc.add_paragraph('游戏分为6大区域，共50关。每区域之间有中场休息室用于存档、整理装备、交易。')

zones = [
    ('区域1：实验室外围（5关）- 新手教学区', [
        ['1-1', '实验室出口', '修门逃生，无武器只能躲', '一人修门，其他人引怪'],
        ['1-2', '武器库', '拾取武器，近战远程分配', '武器分配策略'],
        ['1-3', '升降平台', '修平台+撤离倒计时', '有人留下断后'],
        ['1-4', '黑暗走廊', '全黑，必须拿手电筒', '一人照明，其他人保护'],
        ['1-5', '发电室', '找3个零件重启发电机', '分头找零件，怪物巡逻'],
    ], '中场休息室：安保室'),
    ('区域2：实验楼内部（8关）- 机制引入区', [
        ['2-1', '冷藏库', '低温持续掉血，地上有保暖服', '保暖服只有2件，谁穿？'],
        ['2-2', '毒气室', '毒气泄漏，防毒面具限制视野', '戴面具的人带路'],
        ['2-3', '观察室', '玻璃墙后关着精英怪，打破玻璃放出', '可以选择绕路不打'],
        ['2-4', '档案室', '找门禁卡，柜子里可能藏怪', '翻柜子的紧张感'],
        ['2-5', '电梯井', '垂直攀爬，怪物从下方涌上来', '一人爬，其他人掩护'],
        ['2-6', '手术室', '极狭窄空间，手术台当掩体', '近战优势关卡'],
        ['2-7', '标本室', '大量玻璃罐，打碎有概率掉补给/放怪', '赌狗关卡'],
        ['2-8', '控制室', '破解终端（小游戏）开闸门', '一人破解，其他人防守'],
    ], '中场休息室：员工休息室'),
    ('区域3：办公区（7关）- 战术配合区', [
        ['3-1', '办公大厅', '多入口同时刷怪，隔间掩体', '分工守不同方向'],
        ['3-2', '会议室', '圆桌地形，防守3波怪', '纯防守波次'],
        ['3-3', '服务器机房', '狭窄通道，视野极差，怪物埋伏', '步步为营'],
        ['3-4', '食堂', '开阔区域，桌子可以翻倒当掩体', '动态掩体'],
        ['3-5', '走廊迷宫', '复杂走廊网络，容易迷路', '记路/画地图'],
        ['3-6', '安保室', '激光栅栏，需要找开关关闭', '开关在怪堆里'],
        ['3-7', '经理办公室', '精英怪把守，里面有好武器', '可选挑战'],
    ], '中场休息室：休息室'),
    ('区域4：工业区（7关）- 环境危险区', [
        ['4-1', '仓库', '高大货架遮挡视野，怪物从货架后跳出', '伏击感'],
        ['4-2', '装卸区', '开阔空间，叉车可以驾驶/当掩体', '载具首次出现'],
        ['4-3', '锅炉房', '高温地面掉血，管道会爆炸', '注意环境'],
        ['4-4', '水处理厂', '水中移动减速，怪物在水里更快', '地形劣势'],
        ['4-5', '传送带', '移动平台，需要跳上传送带前进', '跑酷元素'],
        ['4-6', '起重机', '一人操作起重机移开障碍物', '操作手+战斗员分工'],
        ['4-7', '化工区', '腐蚀性地面，需要找安全路径', '路线规划'],
    ], '中场休息室：工头办公室'),
    ('区域5：地下区（7关）- 高压生存区', [
        ['5-1', '地下停车场', '车辆掩体，怪物从车后涌出', '经典恐怖场景'],
        ['5-2', '地铁隧道', '周期性有列车经过，被撞直接倒地', '听声音躲列车'],
        ['5-3', '下水道', '极狭窄，视野差，有水蛭怪', '幽闭恐惧'],
        ['5-4', '地下墓穴', '古老建筑，地面有机关陷阱', '看地板走路'],
        ['5-5', '避难所', 'NPC幸存者，可以交易物资/升级武器', '商店关卡'],
        ['5-6', '深层实验室', '最强实验体，需要配合击杀', '难度峰值'],
        ['5-7', '地下河', '需要游泳/木筏，水中有怪物', '水域关卡'],
    ], '中场休息室：避难所（商店+升级）'),
    ('区域6：特殊区（5关）- 玩法变体区', [
        ['6-1', '全黑实验区', '整个关卡全黑，只有手电筒', '极致恐怖'],
        ['6-2', '设施自毁', '10分钟倒计时，边打边跑', '全程紧张'],
        ['6-3', '巨兽追击', '巨型Boss不能打，只能跑', '逃生关卡'],
        ['6-4', '潜行区', '怪物太强，必须潜行绕过', '玩法切换'],
        ['6-5', '最终出口', 'Boss战+登机/上车逃离', '大结局'],
    ], '大结局'),
]

for zone_name, levels, safe_room in zones:
    doc.add_heading(zone_name, level=2)
    add_table(doc,
        ['关卡', '名称', '核心机制', '合作点'],
        levels)
    doc.add_paragraph(safe_room)

# ==================== 8. 联机职业系统 ====================
doc.add_page_break()
doc.add_heading('八、联机职业系统', level=1)

doc.add_paragraph('为后续联机做准备，每个玩家可选择职业，各有专属被动和装备。')

add_table(doc,
    ['职业', '被动技能', '专属装备', '定位'],
    [
        ['工程师', '修理速度+50%', '可放置自动炮塔', '支援/修理'],
        ['医生', '治疗效果+50%', '可放置医疗站', '治疗'],
        ['侦察兵', '移速+20%，怪物探测+50%', '扫描仪永久装备', '侦察/引怪'],
        ['突击手', '伤害+20%，弹药+50%', '额外武器槽', '输出'],
    ])

doc.add_heading('8.1 网络同步设计', level=2)
doc.add_paragraph('• 玩家位置/旋转同步')
doc.add_paragraph('• 玩家装备/背包同步')
doc.add_paragraph('• 怪物AI在服务端运行，位置同步到客户端')
doc.add_paragraph('• 交互状态同步（谁在修门、进度多少）')
doc.add_paragraph('• 道具拾取同步（谁拿了什么）')
doc.add_paragraph('• 伤害同步（谁打了谁，多少伤害）')

# ==================== 9. UI系统设计 ====================
doc.add_page_break()
doc.add_heading('九、UI系统设计', level=1)

doc.add_heading('9.1 主HUD（游戏内常驻）', level=2)
doc.add_paragraph('• 左下角：血量条+护甲条')
doc.add_paragraph('• 右下角：手持物品图标+名称+弹药数')
doc.add_paragraph('• 右上角：任务道具槽（2格图标）')
doc.add_paragraph('• 右中：消耗品槽（4格图标+数量，数字键1-4提示）')
doc.add_paragraph('• 屏幕中心：准心（拿枪时显示）')
doc.add_paragraph('• 屏幕中下：交互提示（按E做什么）')
doc.add_paragraph('• 屏幕中下：修理/破解进度条')
doc.add_paragraph('• 左上角：穿戴装备小图标（头/身/脚）')
doc.add_paragraph('• 顶部：当前目标提示')
doc.add_paragraph('• 受伤时：屏幕红闪')
doc.add_paragraph('• 状态效果：屏幕边缘图标（中毒/低温/加速等）')

doc.add_heading('9.2 功能界面', level=2)
doc.add_paragraph('• Tab键：大背包界面（详细查看6格+穿戴装备）')
doc.add_paragraph('• ESC：暂停菜单（继续/设置/退出）')
doc.add_paragraph('• 商店界面（避难所/休息室）')
doc.add_paragraph('• 区域加载界面（区域名称+提示）')
doc.add_paragraph('• 队友状态面板（联机时显示队友血量/装备）')
doc.add_paragraph('• 存档/读档界面')

# ==================== 10. 分区域加载策略 ====================
doc.add_page_break()
doc.add_heading('十、分区域加载策略', level=1)

doc.add_heading('10.1 加载规则', level=2)
doc.add_paragraph('• 游戏分为6个区域(Zone)，每区3-8关')
doc.add_paragraph('• 区域之间有中场休息室(Safe Room)：存档、整理装备、交易')
doc.add_paragraph('• 进入新区域时只加载该区域的资产')
doc.add_paragraph('• 离开区域时卸载不需要的资产，释放内存')
doc.add_paragraph('• 避免一次性加载所有场景导致卡顿')

doc.add_heading('10.2 存档内容', level=2)
doc.add_paragraph('• 玩家位置')
doc.add_paragraph('• 血量/护甲')
doc.add_paragraph('• 手持物品')
doc.add_paragraph('• 背包内容（任务道具+消耗品）')
doc.add_paragraph('• 穿戴装备')
doc.add_paragraph('• 已完成关卡')
doc.add_paragraph('• 已拾取道具记录')
doc.add_paragraph('• 储物箱内容')

# ==================== 11. 装备视觉绑定 ====================
doc.add_heading('十一、装备视觉绑定系统', level=1)

doc.add_paragraph('为了让玩家能看出自己和队友的装备状态，所有装备都有对应的视觉表现：')

doc.add_heading('11.1 手持物视觉', level=2)
doc.add_paragraph('• 拿武器 → 第一人称视角手上显示武器模型')
doc.add_paragraph('• 拿工具 → 手上显示工具模型（扳手/手电筒等）')
doc.add_paragraph('• 空手 → 手上什么都没有，可以看到角色的手')

doc.add_heading('11.2 穿戴装备视觉', level=2)
doc.add_paragraph('• 穿防护服 → 身体材质替换为防护服材质（黄色/白色）')
doc.add_paragraph('• 穿保暖服 → 身体变厚，棉衣材质')
doc.add_paragraph('• 穿防弹衣 → 身体加护甲片模型')
doc.add_paragraph('• 戴防毒面具 → 头部加面具模型')
doc.add_paragraph('• 戴夜视仪 → 头部加目镜模型，屏幕泛绿')
doc.add_paragraph('• 戴头盔 → 头部加头盔模型')

doc.add_heading('11.3 受伤视觉反馈', level=2)
doc.add_paragraph('• 受伤 → 屏幕红闪')
doc.add_paragraph('• 低血量 → 屏幕边缘红色脉动')
doc.add_paragraph('• 中毒 → 屏幕绿色边缘')
doc.add_paragraph('• 低温 → 屏幕蓝色边缘+霜冻效果')
doc.add_paragraph('• 队友视角：受伤时身体材质变红/加伤痕效果')

# ==================== 12. 可破坏物体实现 ====================
doc.add_heading('十二、可破坏物体实现方案', level=1)

doc.add_heading('12.1 玻璃墙/玻璃罐实现', level=2)
doc.add_paragraph('玻璃物体 = MeshInstance3D(玻璃材质) + Area3D(碰撞检测)')
doc.add_paragraph('受到攻击/子弹击中时：')
doc.add_paragraph('1. 播放碎裂音效')
doc.add_paragraph('2. 生成碎玻璃粒子（CPUParticles3D）')
doc.add_paragraph('3. 隐藏Mesh，禁用碰撞')
doc.add_paragraph('4. 如果玻璃后有关着的怪物 → 触发怪物释放')
doc.add_paragraph('5. 如果是玻璃罐 → 概率掉落补给/放出小怪')

doc.add_heading('12.2 木箱实现', level=2)
doc.add_paragraph('• 受到一定伤害后打碎')
doc.add_paragraph('• 打碎时生成木屑粒子')
doc.add_paragraph('• 掉落随机补给（医疗包/弹药/道具）')

doc.add_heading('12.3 爆炸桶实现', level=2)
doc.add_paragraph('• 受到伤害后爆炸')
doc.add_paragraph('• 爆炸范围伤害（对玩家和怪物都有效）')
doc.add_paragraph('• 生成火焰+烟雾粒子')
doc.add_paragraph('• 可以利用环境杀（把怪引到爆炸桶旁边打爆）')

# ==================== 13. 开发路线图 ====================
doc.add_page_break()
doc.add_heading('十三、开发路线图', level=1)

roadmap = [
    ('阶段1：核心系统框架', [
        '道具注册系统（ItemManager）',
        '背包系统（6格，任务+消耗品）',
        '穿戴装备系统（头/身/脚）',
        '管理器框架（7个管理器）',
        '分区域加载基础',
    ]),
    ('阶段2：道具+交互完善', [
        '所有手持工具实现',
        '所有武器实现（近战+远程）',
        '投掷物系统',
        '放置物系统',
        '可破坏物体系统',
        '即时消耗品+背包消耗品',
    ]),
    ('阶段3：怪物扩展', [
        '普通怪3种',
        '远程怪3种',
        '特殊怪9种',
        '环境怪4种',
        'Boss 4种',
        '波次系统',
    ]),
    ('阶段4：区域1-2关卡', [
        '实验室外围5关',
        '实验楼内部8关',
        '中场休息室',
        '存档系统',
    ]),
    ('阶段5：区域3-4关卡', [
        '办公区7关',
        '工业区7关',
        '环境危险系统（毒气/低温/高温等）',
    ]),
    ('阶段6：区域5-6关卡', [
        '地下区7关',
        '特殊区5关',
        '商店/交易系统',
        'Boss战',
        '大结局',
    ]),
    ('阶段7：联机', [
        '网络同步框架',
        '职业系统',
        '队友UI',
        '联机测试',
    ]),
]

for phase_name, items in roadmap:
    doc.add_heading(phase_name, level=2)
    for item in items:
        doc.add_paragraph('• ' + item)

# ==================== 保存 ====================
output_path = "E:/GodotProjects/let's_go/docs/游戏设计文档_GDD_v1.0.docx"
doc.save(output_path)
print(f'文档已生成：{output_path}')
