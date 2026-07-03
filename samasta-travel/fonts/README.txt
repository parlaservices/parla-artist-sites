TT Commons Pro — self-hosted brand font
=======================================

The site is wired to use TT Commons Pro as the primary typeface (headings,
lowercase headers, buttons, and the hero "Explore" label). Until the licensed
font files are placed in this folder, the site falls back to DM Sans (loaded
from Google Fonts), so nothing breaks — it just won't show TT Commons Pro yet.

To activate TT Commons Pro, add the licensed WebFont files here with these exact
names (woff2 required; woff optional for older browsers):

  fonts/TTCommonsPro-Regular.woff2   (weight 400)   fonts/TTCommonsPro-Regular.woff
  fonts/TTCommonsPro-Medium.woff2    (weight 500)   fonts/TTCommonsPro-Medium.woff
  fonts/TTCommonsPro-Bold.woff2      (weight 700)   fonts/TTCommonsPro-Bold.woff

The matching @font-face declarations already live at the top of the <style>
block in every page (index, journeys, plan, faqs, contact). No further CSS
changes are needed — once the files are in place the font applies automatically.

Note: the "What's Included in Your Itinerary" section on the journeys page is
intentionally left in DM Sans and will NOT switch to TT Commons Pro.
