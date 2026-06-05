from pathlib import Path

from docx import Document
from docx.shared import Pt
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "competition"
TITLE = "MoonTrustFlow 项目申报书"
PROJECT = "MoonTrustFlow：MoonBit 轻量级数据流安全分析与污染传播检测框架"
PDF = OUT / "MoonTrustFlow项目申报书.pdf"
DOCX = OUT / "MoonTrustFlow项目申报书.docx"

SECTIONS = [
    (
        "一、项目简介",
        "MoonTrustFlow 是一个面向 MoonBit 生态的软件分析基础库。项目通过小型 .mtf 规则语言描述敏感源、危险汇点、净化器、数据流边和允许路径，并在 MoonBit 中实现污染传播分析，输出可解释的 source-to-sink 风险路径。",
    ),
    (
        "二、项目方向与适用场景",
        "项目贴合软件分析框架、工程工具和基础软件生态补位方向。适用场景包括服务端输入到危险操作的数据流建模、AI 生成代码安全审查、CI 架构安全约束检查、可信工具链实验以及后续 MoonBit AST 分析器建设。",
    ),
    (
        "三、核心功能",
        "项目支持 source、sink、sanitizer、node、edge、allow 等声明，能够构建有向数据流图，从 source 出发传播污染标记，在 sanitizer 处截断传播，在 sink 处生成完整风险路径，并用 allow 规则压制已知安全链路。",
    ),
    (
        "四、原创性说明",
        "本项目为原创项目，不移植已有开源项目。项目选择规则模型与污染传播分析作为切入点，避开常见格式解析器、日志处理库和发布工具等容易重合的方向。核心规则语言、数据结构、分析算法、诊断信息和报告格式均围绕 MoonBit 生态重新设计。",
    ),
    (
        "五、技术路线",
        "首版采用行级 .mtf 解析器，将每一行转换为节点、边或策略。分析阶段使用图遍历从敏感源出发记录访问路径；当路径到达危险汇点时生成 finding；当路径到达净化器时停止当前分支；当路径被 allow 规则精确匹配时不报告。",
    ),
    (
        "六、预期成果",
        "项目交付一个可运行、可测试、可复现的 MoonBit 软件分析基础库，包含核心库、CLI 演示、测试集、README、CI、设计文档和申报材料。后续可扩展真实文件读取、风险等级配置、MoonBit AST 适配和 HTML/JSON 报告。",
    ),
]


def font_name() -> str:
    for candidate in [
        Path("C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/simhei.ttf"),
        Path("C:/Windows/Fonts/simsun.ttc"),
    ]:
        if candidate.exists():
            pdfmetrics.registerFont(TTFont("CN", str(candidate)))
            return "CN"
    return "Helvetica"


def build_pdf() -> None:
    font = font_name()
    styles = getSampleStyleSheet()
    title = ParagraphStyle(
        "title",
        parent=styles["Title"],
        fontName=font,
        fontSize=22,
        leading=30,
        alignment=TA_CENTER,
        spaceAfter=18,
    )
    heading = ParagraphStyle(
        "heading",
        parent=styles["Heading2"],
        fontName=font,
        fontSize=13,
        leading=18,
        textColor=colors.HexColor("#1f3b73"),
        spaceBefore=8,
        spaceAfter=4,
    )
    body = ParagraphStyle(
        "body",
        parent=styles["BodyText"],
        fontName=font,
        fontSize=10.5,
        leading=17,
        firstLineIndent=21,
        spaceAfter=4,
    )
    meta = ParagraphStyle("meta", parent=styles["BodyText"], fontName=font, fontSize=10.5, leading=16)
    doc = SimpleDocTemplate(
        str(PDF),
        pagesize=A4,
        rightMargin=2 * cm,
        leftMargin=2 * cm,
        topMargin=1.8 * cm,
        bottomMargin=1.8 * cm,
        title=TITLE,
    )
    story = [Paragraph(TITLE, title)]
    table = Table(
        [
            [Paragraph("项目名称", meta), Paragraph(PROJECT, meta)],
            [Paragraph("参赛方向", meta), Paragraph("MoonBit 国产基础软件开源生态项目", meta)],
            [Paragraph("开源许可证", meta), Paragraph("Apache-2.0", meta)],
            [Paragraph("仓库链接", meta), Paragraph("https://gitlink.org.cn/python123/moontrustflow", meta)],
        ],
        colWidths=[3.2 * cm, 12 * cm],
    )
    table.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, -1), font),
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#edf3ff")),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#9aa9c7")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    story.extend([table, Spacer(1, 0.35 * cm)])
    for section_title, text in SECTIONS:
        story.append(Paragraph(section_title, heading))
        story.append(Paragraph(text, body))
    doc.build(story)


def build_docx() -> None:
    doc = Document()
    doc.styles["Normal"].font.name = "Microsoft YaHei"
    doc.styles["Normal"].font.size = Pt(10.5)
    title = doc.add_heading(TITLE, level=0)
    title.alignment = 1
    table = doc.add_table(rows=4, cols=2)
    table.style = "Table Grid"
    rows = [
        ("项目名称", PROJECT),
        ("参赛方向", "MoonBit 国产基础软件开源生态项目"),
        ("开源许可证", "Apache-2.0"),
        ("仓库链接", "https://gitlink.org.cn/python123/moontrustflow"),
    ]
    for row, (key, value) in zip(table.rows, rows):
        row.cells[0].text = key
        row.cells[1].text = value
    for section_title, text in SECTIONS:
        doc.add_heading(section_title, level=1)
        doc.add_paragraph(text)
    doc.save(DOCX)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    build_pdf()
    build_docx()
    print(PDF)
    print(DOCX)


if __name__ == "__main__":
    main()
