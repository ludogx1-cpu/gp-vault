import re

with open('lib/screens/admin_dashboard_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Tab Names
content = content.replace('text: \"PTC Config\"', 'text: \"Manage PTC Ads\"')
content = content.replace('text: \"Partner Links\"', 'text: \"Affiliate Links\"')
content = content.replace('text: \"Sponsor Banners\"', 'text: \"Bonus Sponsors\"')
content = content.replace('text: \"Ad Placeholders\"', 'text: \"HTML Snippets\"')
content = content.replace('text: \"Notices\"', 'text: \"Update Board\"')

# Section Headings inside Tabs
content = content.replace('\"PTC Config\"', '\"Manage PTC Ads\"')
content = content.replace('\"Post a Notice / Update\"', '\"Post to Update Board\"')
content = content.replace('\"Notice Title\"', '\"Update Title\"')
content = content.replace('\"Notice Message\"', '\"Update Message\"')
content = content.replace('\"POST NOTICE\"', '\"POST UPDATE\"')
content = content.replace('\"Active Notices\"', '\"Active Updates\"')

with open('lib/screens/admin_dashboard_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Success')
