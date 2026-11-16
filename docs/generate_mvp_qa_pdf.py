"""Generate Maekel first-release testing guide PDF (plain language, no short forms)."""

from __future__ import annotations

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.graphics.shapes import Drawing, Rect, String, Line, Polygon

OUT = Path(__file__).with_name("mvp-qa-guide.pdf")

C_INK = colors.HexColor("#1C1917")
C_MUTED = colors.HexColor("#57534E")
C_LINE = colors.HexColor("#D6D3D1")
C_BG = colors.HexColor("#FAFAF9")
C_ACCENT = colors.HexColor("#C2410C")
C_RIDE = colors.HexColor("#0F766E")
C_FOOD = colors.HexColor("#B45309")
C_MARKET = colors.HexColor("#1D4ED8")
C_PLATFORM = colors.HexColor("#44403C")
C_OK = colors.HexColor("#15803D")
C_WARN = colors.HexColor("#B91C1C")
C_BOX = colors.HexColor("#FFF7ED")
C_WHITE = colors.white


def styles():
    base = getSampleStyleSheet()
    return {
        "cover_title": ParagraphStyle(
            "cover_title", parent=base["Title"], fontName="Helvetica-Bold",
            fontSize=22, textColor=C_INK, alignment=TA_CENTER, spaceAfter=6,
        ),
        "cover_sub": ParagraphStyle(
            "cover_sub", parent=base["Normal"], fontName="Helvetica",
            fontSize=11, textColor=C_MUTED, alignment=TA_CENTER, leading=15, spaceAfter=5,
        ),
        "h1": ParagraphStyle(
            "h1", parent=base["Heading1"], fontName="Helvetica-Bold",
            fontSize=14, textColor=C_INK, spaceBefore=4, spaceAfter=8,
        ),
        "h2": ParagraphStyle(
            "h2", parent=base["Heading2"], fontName="Helvetica-Bold",
            fontSize=11, textColor=C_ACCENT, spaceBefore=10, spaceAfter=5,
        ),
        "body": ParagraphStyle(
            "body", parent=base["Normal"], fontName="Helvetica",
            fontSize=9.5, textColor=C_INK, leading=13, spaceAfter=6,
        ),
        "small": ParagraphStyle(
            "small", parent=base["Normal"], fontName="Helvetica",
            fontSize=8, textColor=C_MUTED, leading=11, spaceAfter=4,
        ),
        "caption": ParagraphStyle(
            "caption", parent=base["Normal"], fontName="Helvetica-Oblique",
            fontSize=8, textColor=C_MUTED, alignment=TA_CENTER, spaceBefore=3, spaceAfter=10,
        ),
        "bullet": ParagraphStyle(
            "bullet", parent=base["Normal"], fontName="Helvetica",
            fontSize=9, textColor=C_INK, leading=12,
        ),
        "th": ParagraphStyle(
            "th", parent=base["Normal"], fontName="Helvetica-Bold",
            fontSize=8, textColor=C_INK, leading=10,
        ),
        "td": ParagraphStyle(
            "td", parent=base["Normal"], fontName="Helvetica",
            fontSize=8, textColor=C_INK, leading=10,
        ),
        "us_id": ParagraphStyle(
            "us_id", parent=base["Normal"], fontName="Helvetica-Bold",
            fontSize=10, textColor=C_ACCENT, spaceBefore=7, spaceAfter=2,
        ),
        "us_story": ParagraphStyle(
            "us_story", parent=base["Normal"], fontName="Helvetica-Oblique",
            fontSize=8.5, textColor=C_INK, leading=11, spaceAfter=3,
        ),
        "ac": ParagraphStyle(
            "ac", parent=base["Normal"], fontName="Helvetica",
            fontSize=8, textColor=C_INK, leading=11, leftIndent=8, spaceAfter=1,
        ),
        "epic": ParagraphStyle(
            "epic", parent=base["Heading2"], fontName="Helvetica-Bold",
            fontSize=11, textColor=C_INK, spaceBefore=8, spaceAfter=5,
        ),
    }


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(C_LINE)
    canvas.setLineWidth(0.5)
    canvas.line(18 * mm, 14 * mm, A4[0] - 18 * mm, 14 * mm)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(C_MUTED)
    canvas.drawString(18 * mm, 8 * mm, "Maekel first-release testing guide  |  Internal")
    canvas.drawRightString(A4[0] - 18 * mm, 8 * mm, f"Page {doc.page}")
    canvas.restoreState()


def box(d, x, y, w, h, fill, label, sub=None, radius=4):
    d.add(Rect(x, y, w, h, rx=radius, ry=radius, fillColor=fill, strokeColor=C_LINE, strokeWidth=0.8))
    light = fill in (C_BOX, C_BG)
    d.add(String(
        x + w / 2, y + h / 2 + (3 if sub else 0), label,
        fontName="Helvetica-Bold", fontSize=7.5,
        fillColor=C_INK if light else C_WHITE, textAnchor="middle",
    ))
    if sub:
        d.add(String(
            x + w / 2, y + h / 2 - 9, sub,
            fontName="Helvetica", fontSize=6,
            fillColor=C_MUTED if light else C_WHITE, textAnchor="middle",
        ))


def arrow(d, x1, y1, x2, y2):
    import math
    d.add(Line(x1, y1, x2, y2, strokeColor=C_MUTED, strokeWidth=1.2))
    ang = math.atan2(y2 - y1, x2 - x1)
    size = 5
    d.add(Polygon(
        [x2, y2, x2 - size * math.cos(ang - 0.4), y2 - size * math.sin(ang - 0.4),
         x2 - size * math.cos(ang + 0.4), y2 - size * math.sin(ang + 0.4)],
        fillColor=C_MUTED, strokeColor=C_MUTED,
    ))


def diagram_architecture():
    d = Drawing(480, 255)
    d.add(Rect(0, 0, 480, 255, fillColor=C_BG, strokeColor=C_LINE, strokeWidth=0.5))
    d.add(String(240, 238, "How the app connects", fontName="Helvetica-Bold", fontSize=10, fillColor=C_INK, textAnchor="middle"))
    box(d, 170, 195, 140, 28, C_ACCENT, "Maekel phone app")
    arrow(d, 240, 195, 240, 172)
    box(d, 150, 142, 180, 28, C_PLATFORM, "Front door to all services")
    y = 90
    for x, name in [(15, "Sign-in"), (100, "Places"), (185, "Photos"), (270, "Alerts"), (355, "Chat")]:
        box(d, x, y, 72, 26, C_PLATFORM, name)
        arrow(d, 240, 142, x + 36, y + 26)
    y2 = 28
    box(d, 40, y2, 110, 36, C_RIDE, "Ride system", "own data")
    box(d, 185, y2, 110, 36, C_FOOD, "Food system", "own data")
    box(d, 330, y2, 110, 36, C_MARKET, "Market system", "own data")
    arrow(d, 240, 142, 95, y2 + 36)
    arrow(d, 240, 142, 240, y2 + 36)
    arrow(d, 240, 142, 385, y2 + 36)
    return d


def diagram_roles():
    d = Drawing(480, 195)
    d.add(Rect(0, 0, 480, 195, fillColor=C_BG, strokeColor=C_LINE, strokeWidth=0.5))
    d.add(String(240, 175, "One phone number = one account = many roles", fontName="Helvetica-Bold", fontSize=10, fillColor=C_INK, textAnchor="middle"))
    box(d, 165, 125, 150, 32, C_ACCENT, "Phone +251 9…", "one person")
    arrow(d, 240, 125, 90, 90)
    arrow(d, 240, 125, 240, 90)
    arrow(d, 240, 125, 390, 90)
    box(d, 25, 48, 130, 40, C_RIDE, "Ride", "Passenger and driver")
    box(d, 175, 48, 130, 40, C_FOOD, "Food", "Customer / shop / courier")
    box(d, 325, 48, 130, 40, C_MARKET, "Market", "Buyer and seller")
    d.add(String(240, 18, "Check: switching role must not need a second registration", fontName="Helvetica-Oblique", fontSize=8, fillColor=C_MUTED, textAnchor="middle"))
    return d


def diagram_ride_states():
    d = Drawing(480, 215)
    d.add(Rect(0, 0, 480, 215, fillColor=C_BG, strokeColor=C_LINE, strokeWidth=0.5))
    d.add(String(240, 195, "Ride trip steps (check each step)", fontName="Helvetica-Bold", fontSize=10, fillColor=C_INK, textAnchor="middle"))
    states = [(10, "Requested"), (90, "Looking"), (170, "Matched"), (250, "Coming"), (330, "Arrived"), (400, "On trip")]
    y = 135
    for i, (x, name) in enumerate(states):
        box(d, x, y, 70, 28, C_RIDE, name)
        if i < len(states) - 1:
            arrow(d, x + 70, y + 14, states[i + 1][0], y + 14)
    box(d, 150, 65, 85, 28, C_OK, "Finished")
    box(d, 270, 65, 85, 28, C_WARN, "Cancelled")
    arrow(d, 435, 135, 230, 93)
    arrow(d, 205, 135, 310, 93)
    d.add(String(15, 35, "Critical: tapping Request twice must not create two trips", fontName="Helvetica", fontSize=8, fillColor=C_WARN))
    d.add(String(15, 18, "Critical: price at the end must match the price shown before Request", fontName="Helvetica", fontSize=8, fillColor=C_WARN))
    return d


def diagram_food_flow():
    d = Drawing(480, 225)
    d.add(Rect(0, 0, 480, 225, fillColor=C_BG, strokeColor=C_LINE, strokeWidth=0.5))
    d.add(String(240, 205, "Food order: who does what", fontName="Helvetica-Bold", fontSize=10, fillColor=C_INK, textAnchor="middle"))
    steps = [
        (10, 145, "Customer", "Places order", C_FOOD),
        (110, 145, "Shop", "Accepts / cooks", C_FOOD),
        (210, 145, "Courier", "Picks up", C_FOOD),
        (310, 145, "Customer", "Gives code", C_ACCENT),
        (400, 145, "System", "Delivered", C_OK),
    ]
    for i, (x, y, a, b, c) in enumerate(steps):
        box(d, x, y, 82, 36, c, a, b)
        if i < len(steps) - 1:
            arrow(d, x + 82, y + 18, steps[i + 1][0], y + 18)
    for i, label in enumerate(["Confirmed", "Preparing", "Picked up", "On the way", "Delivered"]):
        box(d, 15 + i * 92, 65, 85, 24, C_BOX, label)
        if i < 4:
            arrow(d, 15 + i * 92 + 85, 77, 15 + (i + 1) * 92, 77)
    d.add(String(15, 32, "Cancel only before the shop starts preparing", fontName="Helvetica", fontSize=8, fillColor=C_WARN))
    d.add(String(15, 15, "Critical: delivered only after the correct delivery verification code", fontName="Helvetica", fontSize=8, fillColor=C_WARN))
    return d


def diagram_market_flow():
    d = Drawing(480, 205)
    d.add(Rect(0, 0, 480, 205, fillColor=C_BG, strokeColor=C_LINE, strokeWidth=0.5))
    d.add(String(240, 185, "Market: post, review, then buyers can see it", fontName="Helvetica-Bold", fontSize=10, fillColor=C_INK, textAnchor="middle"))
    box(d, 15, 115, 88, 36, C_MARKET, "Sell", "photos + details")
    arrow(d, 103, 133, 120, 133)
    box(d, 120, 115, 88, 36, C_WARN, "Waiting", "NOT public")
    arrow(d, 208, 133, 225, 133)
    box(d, 225, 115, 88, 36, C_OK, "Approved", "shown in search")
    arrow(d, 313, 133, 330, 133)
    box(d, 330, 115, 88, 36, C_MARKET, "Buyer", "search / filter")
    box(d, 380, 50, 88, 36, C_ACCENT, "Chat / Call", "agree meetup")
    arrow(d, 374, 115, 410, 86)
    box(d, 225, 50, 88, 36, C_WARN, "Rejected", "with reason")
    arrow(d, 269, 115, 269, 86)
    d.add(String(15, 20, "Critical: listings waiting for review must never appear in public search", fontName="Helvetica", fontSize=8, fillColor=C_WARN))
    return d


def diagram_supply_pools():
    d = Drawing(480, 155)
    d.add(Rect(0, 0, 480, 155, fillColor=C_BG, strokeColor=C_LINE, strokeWidth=0.5))
    d.add(String(240, 135, "These job groups stay separate in the first release", fontName="Helvetica-Bold", fontSize=10, fillColor=C_INK, textAnchor="middle"))
    box(d, 30, 55, 130, 50, C_RIDE, "Ride drivers", "car trips")
    box(d, 175, 55, 130, 50, C_FOOD, "Food couriers", "deliver orders")
    box(d, 320, 55, 130, 50, C_MARKET, "Market sellers", "classified ads")
    d.add(String(240, 22, "Same phone can hold more than one role — job lists are still separate", fontName="Helvetica-Oblique", fontSize=8, fillColor=C_MUTED, textAnchor="middle"))
    return d


def diagram_exit_gate():
    d = Drawing(480, 190)
    d.add(Rect(0, 0, 480, 190, fillColor=C_BG, strokeColor=C_LINE, strokeWidth=0.5))
    d.add(String(240, 170, "Ready to release only when all of these pass", fontName="Helvetica-Bold", fontSize=10, fillColor=C_INK, textAnchor="middle"))
    for x, y, label in [
        (20, 110, "Sign-in works"),
        (140, 110, "Ride cash trip"),
        (260, 110, "Food + code"),
        (370, 110, "Market chat"),
        (70, 45, "No re-login"),
        (200, 45, "Area messages"),
        (330, 45, "Can suspend"),
    ]:
        box(d, x, y, 100, 32, C_BOX, label)
    return d


def make_table(data, col_widths, s):
    styled = [[Paragraph(cell, s["th"] if r == 0 else s["td"]) for cell in row] for r, row in enumerate(data)]
    t = Table(styled, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#FED7AA")),
        ("GRID", (0, 0), (-1, -1), 0.4, C_LINE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [C_WHITE, colors.HexColor("#F5F5F4")]),
    ]))
    return t


def bullets(items, s):
    return ListFlowable(
        [ListItem(Paragraph(i, s["bullet"]), leftIndent=8, bulletColor=C_ACCENT) for i in items],
        bulletType="bullet", start="•", leftIndent=12, spaceBefore=2, spaceAfter=8,
    )


def add_user_story(story, s, uid, title, narrative, criteria):
    block = [
        Paragraph(f"{uid} — {title}", s["us_id"]),
        Paragraph(narrative, s["us_story"]),
        Paragraph("<b>What must be true</b>  (tick when you have checked it)", s["small"]),
    ]
    for c in criteria:
        block.append(Paragraph(f"☐  {c}", s["ac"]))
    block.append(Spacer(1, 2.5 * mm))
    story.append(KeepTogether(block))


USER_STORIES = [
    ("Group A — Sign-in and Home", [
        ("Story A01", "Sign in with phone and verification code",
         "As a new customer, I want to sign in with my Ethiopian phone number and a verification code, so that I can use Maekel with one account.",
         ["I can enter a valid Ethiopian mobile number (country code +251)",
          "After I enter the correct verification code, I reach the Home screen",
          "If the code is wrong, I see a clear error and I am not signed in",
          "After I sign in once, opening Ride, Food, or Market does not ask me to sign in again",
          "When I sign out, I return to the sign-in screen and my session is cleared"]),
        ("Story A02", "Home screen shortcuts",
         "As a signed-in customer, I want clear buttons for Ride, Food, and Market, so that I can open each part quickly.",
         ["Home shows the Maekel name and entries for Ride, Food, and Market",
          "Tapping each entry opens that part without the app crashing",
          "Games can be a simple placeholder and must not block the first release",
          "Leaving a part and returning to Home keeps me signed in"]),
        ("Story A03", "Same phone, different roles",
         "As a customer, I want one phone number to work as passenger and driver, and as buyer and seller, so that I do not need two accounts.",
         ["The same account can use Ride as a passenger and, after approval, as a driver",
          "The same account can browse Market and also sell / manage my ads",
          "Switching role does not require registering a second phone number",
          "Special roles stay blocked until someone approves them"]),
        ("Story A04", "Saved addresses",
         "As a customer, I want to save places I use often, so that ordering food is faster.",
         ["I can save at least one place with a name (for example Home or Work)",
          "Food checkout can use a saved place",
          "If a place is outside the delivery area, I see a clear message"]),
    ]),
    ("Group B — Ride (passenger)", [
        ("Story B01", "Choose pickup and drop-off",
         "As a passenger, I want to set where I am picked up and where I go, so that I can request a trip in Addis Ababa.",
         ["Pickup can use my phone location, or I can move the pin / search",
          "I can set drop-off by search or by moving the pin",
          "Outside the service area, I cannot request a trip, and the message is clear"]),
        ("Story B02", "See the price before I request",
         "As a passenger, I want to see the trip price in Ethiopian Birr before I request, so that I am not surprised later.",
         ["After pickup and drop-off, the price is shown in Ethiopian Birr",
          "The first release shows one car type only",
          "I cannot tap Request until I have seen the price",
          "On a normal successful trip, the end price matches the price shown before Request"]),
        ("Story B03", "Request and get a driver",
         "As a passenger, I want to request a ride and be matched with a driver, so that someone comes to pick me up.",
         ["After Request, I see a looking-for-driver state",
          "When matched, I see name, photo or placeholder, rating, car, plate, and how soon they arrive",
          "If I tap Request twice by mistake, only one trip is created",
          "If no driver is found, I see a clear message and I can try again"]),
        ("Story B04", "Follow the trip on the map",
         "As a passenger, I want to see the driver on the map, so that I know when they are coming.",
         ["After assign, the map shows the driver moving toward pickup",
          "Status moves: assigned → arriving → arrived → on trip → finished or cancelled",
          "During the trip, the map shows progress toward drop-off",
          "From Home I can open the active trip again"]),
        ("Story B05", "Contact the driver",
         "As a passenger, I want to contact my driver, so that we can coordinate pickup.",
         ["After matching, call or in-app chat works (at least one)"]),
        ("Story B06", "Cancel before the trip starts",
         "As a passenger, I want to cancel before the trip starts, so that I am not forced to ride.",
         ["Cancel is available before the trip is in progress",
          "After cancel, status is cancelled and the driver is freed"]),
        ("Story B07", "Pay cash, rate, and see past trips",
         "As a passenger, I want to pay with cash, rate the driver, and see past trips, so that the trip feels complete.",
         ["Cash amount is clear to passenger and driver",
          "I can leave a rating from 1 to 5",
          "Trip appears in history with price, time, and driver summary"]),
    ]),
    ("Group C — Ride (driver)", [
        ("Story C01", "Go online and receive trip offers",
         "As an approved driver, I want to go online and receive trip offers, so that I can earn money.",
         ["A driver who is not approved cannot go online",
          "Online / offline switch works",
          "An offer shows pickup area, price estimate, and time to accept"]),
        ("Story C02", "Finish the driver steps for a trip",
         "As a driver, I want to accept → mark arrived → start → complete, so that the trip steps are correct.",
         ["Accept links me to the passenger trip",
          "I can mark Arrived, Start, and Complete in order",
          "I can confirm cash collected when needed",
          "Today’s earnings list updates after complete",
          "Reporting a problem does not crash the app"]),
    ]),
    ("Group D — Food (customer)", [
        ("Story D01", "See shops that can deliver to me",
         "As a customer, I want to see restaurants and grocery shops that deliver to my pin, so that I only browse what I can order.",
         ["I set or confirm a delivery place before or when browsing",
          "Only shops that can deliver there are shown",
          "Restaurants/food and groceries are available",
          "Each shop shows name, open or closed, and fee or time hint",
          "Outside the area, I see a clear empty or blocked message"]),
        ("Story D02", "Build a cart from one shop",
         "As a customer, I want to add items from one shop, so that I can check out a single order.",
         ["Each item shows price in Ethiopian Birr and availability",
          "Unavailable items cannot be added (or are clearly blocked)",
          "Cart shows items, subtotal, delivery fee, and total",
          "One cart is for one shop only in the first release"]),
        ("Story D03", "Place an order paid with cash on delivery",
         "As a customer, I want to confirm my address and place an order paid with cash when it arrives, so that the shop can prepare my food.",
         ["Before I place the order, I see the exact delivery fee",
          "Paying with cash on delivery is available",
          "I get an order number and a confirmed status",
          "Minimum order amount is enforced when the shop has one"]),
        ("Story D04", "Follow the order and confirm with a delivery code",
         "As a customer, I want to follow status and confirm handover with a delivery verification code, so that delivery is safer.",
         ["Status moves: confirmed → preparing → picked up → on the way → delivered or cancelled",
          "I receive a delivery verification code",
          "Order cannot show as delivered without the correct code (unless an admin specially overrides)",
          "Order appears in my history"]),
        ("Story D05", "Cancel only before the shop starts preparing",
         "As a customer, I want to cancel only before preparing starts, so that shops do not waste food and time.",
         ["I can cancel while the order is only confirmed",
          "After preparing has started, cancel is blocked with a clear message"]),
    ]),
    ("Group E — Food (shop and delivery person)", [
        ("Story E01", "Shop accepts and prepares the order",
         "As a shop, I want to accept and prepare orders, so that a delivery person can pick them up.",
         ["A new order is visible (and ideally notifies me)",
          "I can accept or reject",
          "I can mark preparing and ready for pickup",
          "I can pause my shop"]),
        ("Story E02", "Delivery person finishes with the verification code",
         "As a food delivery person, I want to finish delivery with the customer’s verification code, so that cash handovers are checked.",
         ["I see pickup and drop-off details",
          "I can mark picked up and on the way",
          "Finishing requires the customer’s verification code",
          "Cash amount to collect is shown when needed",
          "Food delivery people are a separate group from Ride drivers"]),
    ]),
    ("Group F — Market (buy and sell)", [
        ("Story F01", "Browse and search listings",
         "As a buyer, I want to browse categories and search or filter listings, so that I find items near me.",
         ["At least four to six main categories are available",
          "Keyword search works",
          "I can filter by place, price, and condition",
          "Cards show photo, price in Ethiopian Birr, title, and place",
          "Only approved listings appear in public browse and search"]),
        ("Story F02", "Open a listing and contact the seller",
         "As a buyer, I want to open a listing and chat or call the seller, so that we can agree on a meetup.",
         ["Detail shows photos, description, key details, and seller info",
          "Safety tips appear before the first contact",
          "In-app chat sends and receives text",
          "Call button works according to the seller’s phone setting",
          "Chat shows a safety reminder (do not pay before you see the item)"]),
        ("Story F03", "Save favorite listings",
         "As a buyer, I want to save favorites, so that I can find them again later.",
         ["I can add and remove a favorite",
          "My favorites list shows what I saved"]),
        ("Story F04", "Post something for sale",
         "As a seller, I want to post a listing with photos and details, so that buyers can find it after approval.",
         ["Sell flow: category → photos → title and description → price → details → place → submit",
          "I can upload more than one photo",
          "After submit, the listing is waiting for review and not public",
          "Maximum active free listings is enforced when configured"]),
        ("Story F05", "Review listings before they go public",
         "As a reviewer, I want to approve or reject listings, so that only safe ads go live.",
         ["I can see listings waiting for review",
          "Approve makes the listing public and notifies the seller",
          "Reject keeps it off public search and shows a reason",
          "A report from a buyer is visible to the review team"]),
        ("Story F06", "Manage my listings",
         "As a seller, I want to manage my listings, so that I can edit, close, or mark them sold.",
         ["My ads shows active, waiting, rejected, and sold",
          "Edit works (big changes may need review again)",
          "Mark sold or delete closes the listing clearly"]),
    ]),
    ("Group G — Across the app / ready to release", [
        ("Story G01", "One sign-in for the whole app",
         "As a customer, I want one sign-in for Ride, Food, and Market, so that Maekel feels like one product.",
         ["After I sign in once, moving between Ride, Food, and Market never asks for a new verification code"]),
        ("Story G02", "Stop a bad user",
         "As an admin, I want to suspend a user, so that we can stop abuse.",
         ["A suspended user cannot request rides, place food orders, or post Market ads (as designed)",
          "Their public Market ads can be taken down when needed"]),
        ("Story G03", "Final ready-to-release checklist",
         "As the person signing off the first release, I want one final list, so that we know we can launch.",
         ["Stories A01–A03 pass",
          "A full Ride cash trip passes (Groups B and C)",
          "A full Food cash-on-delivery trip with verification code passes (Groups D and E)",
          "Market post → review → browse → chat passes (Group F)",
          "No critical open problems: two trips from one request, delivered without verification code, waiting listing shown to public, or signing in without a valid code",
          "Outside-area messages checked for Ride and Food"]),
    ]),
]


def build():
    s = styles()
    doc = SimpleDocTemplate(
        str(OUT), pagesize=A4,
        leftMargin=16 * mm, rightMargin=16 * mm, topMargin=15 * mm, bottomMargin=18 * mm,
        title="Maekel First-Release Testing Guide", author="Maekel",
    )
    story = []

    story.append(Spacer(1, 22 * mm))
    story.append(Paragraph("Maekel", s["cover_title"]))
    story.append(Paragraph("First-release testing guide", s["cover_title"]))
    story.append(Paragraph("and checklist", s["cover_title"]))
    story.append(Spacer(1, 5 * mm))
    story.append(Paragraph(
        "Ride (call a car) · Food (order meals or groceries) · Market (buy and sell)",
        s["cover_sub"],
    ))
    story.append(Spacer(1, 6 * mm))
    story.append(Paragraph("Version 0.4  ·  15 November 2026  ·  Addis Ababa  ·  Ethiopian Birr  ·  +251", s["cover_sub"]))
    story.append(Spacer(1, 10 * mm))
    story.append(Paragraph(
        "Use this as the <b>launch checklist</b>. Read each short story, then tick every box under "
        "<b>What must be true</b>. A story is finished only when every box is ticked. "
        "If a critical problem is still open, the first release is not ready.",
        s["body"],
    ))
    story.append(PageBreak())

    story.append(Paragraph("1. How the system is built", s["h1"]))
    story.append(Paragraph(
        "The phone app talks to one front door. Ride, Food, and Market each have their own system behind it. "
        "If chat alerts fail, a food order or a car trip should still be able to finish.",
        s["body"],
    ))
    story.append(diagram_architecture())
    story.append(Paragraph("Picture 1 — Phone app → front door → shared tools + Ride / Food / Market", s["caption"]))

    story.append(Paragraph("2. One phone, many roles", s["h1"]))
    story.append(Paragraph(
        "One phone number creates one Maekel account. That same person can be a passenger and a driver, "
        "or a buyer and a seller, after the right approvals. They must not need a second registration.",
        s["body"],
    ))
    story.append(diagram_roles())
    story.append(Paragraph("Picture 2 — Same phone across Ride, Food, and Market", s["caption"]))

    story.append(Paragraph("Suggested people for testing", s["h2"]))
    story.append(make_table([
        ["Label", "Who they act as", "Notes"],
        ["Person 1", "Everyday customer", "Passenger, food customer, Market buyer and seller"],
        ["Person 2", "Ride driver", "Must be approved before going online"],
        ["Person 3", "Restaurant or shop", "Accepts and prepares food orders"],
        ["Person 4", "Food delivery person", "Finishes delivery with the customer’s verification code"],
        ["Person 5", "Reviewer / admin", "Approves Market ads and can suspend a bad user"],
    ], [55, 120, 255], s))
    story.append(PageBreak())

    story.append(Paragraph("3. What is in the first release (and what is not)", s["h1"]))
    story.append(Paragraph("Must work", s["h2"]))
    story.append(bullets([
        "Sign in with phone and verification code, then open Ride, Food, and Market without signing in again",
        "Ride: one car type, price shown before request, match a driver, live map, pay with cash, rate",
        "Food: restaurants and groceries, one-shop cart, cash on delivery, status steps, delivery verification code",
        "Market: several categories, post with photos, review before public, search, chat and call, favorites",
    ], s))
    story.append(Paragraph("Not required for this launch", s["h2"]))
    story.append(bullets([
        "Playable games, reward points, paid “boost” ads",
        "Pharmacy, parcel courier, ordering from two shops in one cart",
        "Booking a ride for later, live map of the food courier, extra car types",
    ], s))
    story.append(diagram_supply_pools())
    story.append(Paragraph("Picture 3 — Ride drivers, food couriers, and Market sellers stay separate", s["caption"]))
    story.append(PageBreak())

    story.append(Paragraph("4. Ride — pictures and quick checks", s["h1"]))
    story.append(diagram_ride_states())
    story.append(Paragraph("Picture 4 — Trip steps to watch during a test", s["caption"]))
    story.append(make_table([
        ["Check", "What you do", "What you should see", "How serious"],
        ["1", "Set pickup and drop-off", "Price in Ethiopian Birr before Request", "Critical"],
        ["2", "Request with a driver online", "Driver name, car, plate, arrival time", "Critical"],
        ["3", "Watch the map", "Driver moves; status updates", "Critical"],
        ["4", "Finish and pay cash", "Same price as before; rating works", "Critical"],
        ["5", "Tap Request twice", "Only one trip is created", "Critical"],
        ["6", "Cancel before start", "Trip cancelled; driver freed", "Major"],
        ["7", "Go to Home mid-trip", "You can open the active trip again", "Major"],
        ["8", "Driver completes the steps", "Earnings list updates", "Critical"],
        ["9", "Try outside Addis area", "Clear blocked message", "Major"],
        ["10", "Unapproved driver goes online", "Blocked until approved", "Major"],
    ], [35, 130, 200, 55], s))
    story.append(PageBreak())

    story.append(Paragraph("5. Food — pictures and quick checks", s["h1"]))
    story.append(diagram_food_flow())
    story.append(Paragraph("Picture 5 — Customer, shop, courier, and delivery verification code", s["caption"]))
    story.append(make_table([
        ["Check", "What you do", "What you should see", "How serious"],
        ["1", "Set an Addis delivery place", "Shops that can deliver are listed", "Critical"],
        ["2", "Use a place outside the area", "Clear empty or blocked message", "Major"],
        ["3", "Add items to the cart", "Totals correct; one shop only", "Critical"],
        ["4", "Open checkout", "Delivery fee visible before placing order", "Critical"],
        ["5", "Place cash-on-delivery order", "Order number; confirmed status", "Critical"],
        ["6", "Shop accepts and prepares", "Customer sees status updates", "Critical"],
        ["7", "Try cancel after preparing", "Cancel blocked with clear message", "Critical"],
        ["8", "Try finish without the code", "Must fail; not delivered", "Critical"],
        ["9", "Finish with the correct code", "Delivered; shows in history", "Critical"],
        ["10", "Order from a grocery shop", "Same cart and checkout work", "Major"],
    ], [35, 130, 200, 55], s))
    story.append(PageBreak())

    story.append(Paragraph("6. Market — pictures and quick checks", s["h1"]))
    story.append(diagram_market_flow())
    story.append(Paragraph("Picture 6 — Nothing goes public until it is approved", s["caption"]))
    story.append(make_table([
        ["Check", "What you do", "What you should see", "How serious"],
        ["1", "Browse and search", "Results by place, price, condition", "Critical"],
        ["2", "Post with photos", "Waiting for review; not in public search", "Critical"],
        ["3", "Reviewer approves", "Listing becomes public; seller notified", "Critical"],
        ["4", "Reviewer rejects", "Stays private; reason shown", "Major"],
        ["5", "Buyer opens chat", "Messages send and arrive", "Critical"],
        ["6", "Buyer uses Call", "Call works as designed", "Major"],
        ["7", "Save a favorite", "Shows in favorites list", "Major"],
        ["8", "Edit or mark sold", "My ads updates correctly", "Major"],
        ["9", "Report a listing", "Review team can see the report", "Major"],
        ["10", "Safety tips", "Shown before first contact", "Minor"],
    ], [35, 130, 200, 55], s))
    story.append(PageBreak())

    story.append(Paragraph("7. User stories checklist (main launch list)", s["h1"]))
    story.append(Paragraph(
        "This is the main checklist for launch. Tick every empty box when you have checked it yourself. "
        "A story is finished only when every line under it is ticked.",
        s["body"],
    ))
    story.append(Paragraph(
        "Groups: A Sign-in (4) · B Ride passenger (7) · C Ride driver (2) · "
        "D Food customer (5) · E Food shop and courier (2) · F Market (6) · G Ready to release (3) "
        "= <b>29 stories</b>",
        s["small"],
    ))

    for epic_title, stories in USER_STORIES:
        story.append(Paragraph(epic_title, s["epic"]))
        for uid, title, narrative, criteria in stories:
            add_user_story(story, s, uid, title, narrative, criteria)
        story.append(PageBreak())

    story.append(Paragraph("8. Quick checks across the whole app", s["h1"]))
    story.append(make_table([
        ["Check", "What you do", "What you should see", "How serious"],
        ["1", "Sign in once; open all three parts", "No second verification code", "Critical"],
        ["2", "Same phone: passenger and driver", "Role switch works", "Critical"],
        ["3", "Same phone: buy and sell on Market", "No second account needed", "Critical"],
        ["4", "Admin suspends a user", "They cannot post or request as designed", "Critical"],
        ["5", "Alerts fail or are delayed", "Main flows can still finish", "Major"],
        ["6", "Weak network while uploading photos", "Retry works; listing not corrupted", "Major"],
    ], [35, 150, 190, 55], s))

    story.append(Paragraph("9. Ready-to-release gate", s["h1"]))
    story.append(diagram_exit_gate())
    story.append(Paragraph("Picture 7 — All of these must pass before launch", s["caption"]))
    story.append(Paragraph("Also complete <b>Story G03</b>. Short reminders:", s["body"]))
    story.append(bullets([
        "Sign in → Home → Ride, Food, and Market without signing in again",
        "Full Ride cash trip (including only one trip if Request is tapped twice)",
        "Full Food order paid with cash on delivery, finished with verification code",
        "Market: post → review → browse → chat",
        "Clear messages when outside the service area",
        "No critical open problems",
        "Admin can suspend a bad user",
    ], s))

    story.append(Paragraph("10. How serious is the problem?", s["h2"]))
    story.append(make_table([
        ["Level", "Meaning", "Examples"],
        ["Critical", "Must fix before launch", "Sign-in without a valid code; two trips from one request; delivered without verification code; waiting listing already public"],
        ["Major", "Should fix before first release if it is on this list", "Wrong final price; chat not sending; cancel allowed after preparing started"],
        ["Minor", "Can fix soon after launch", "Wording, layout, small polish"],
        ["Later", "Not part of this launch", "Reward points, paid boost ads, pharmacy, and similar"],
    ], [55, 140, 235], s))

    story.append(Spacer(1, 6 * mm))
    story.append(Paragraph(
        "Related reading (more technical): first-release scope note, architecture note, and full product requirement notes for Ride, Food, and Market.",
        s["small"],
    ))

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    build()
