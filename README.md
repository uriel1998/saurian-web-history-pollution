#Saurian Spider

A BASH script to pollute your web history a little bit to make ISP snooping a little more difficult.

In 2016, the FCC ruled that internet service providers had to [get your permission before selling your raw browsing data
](http://www.recode.net/2016/10/28/13442880/internet-providers-fcc-permission-share-web-browsing-data-opt-in).

While that wasn't hard for them to do, the [Trump-led GOP is trying to remove that tiny bit of privacy](https://arstechnica.com/tech-policy/2017/03/gop-senators-new-bill-would-let-isps-sell-your-web-browsing-data/).

While there's little substitute for tools such as HTTPS Everywhere, a VPN, and setting your DNS to ones other than your ISPs, this script is something I whipped up to pollute your web browsing history.

It maintains a list of URLs - creating one at $HOME/.config/saurianspider.conf if needed - and retrieves them randomly at random-ish intervals. Any new links it finds on those pages, it'll add to the list. It also switches the useragent between Firefox, Chrome, Opera, Opera Mini, Edge, and Internet Exploder semi-randomly as well, thus making it more difficult to filter out these requests from your legit ones.

The URL list is seeded with the current events page at Wikipedia and the "Random" page on Wikipedia; that said, it doesn't ADD links from Wikipedia or Wikimedia, as that could get really obvious, really quickly.

If you want to use your own list of URLs in a different location, the file location should be the first (and only) argument.

Depends upon/uses (most of these are GNU coreutils):

curl  
awk  
sed  
head & tail   
grep  
mktemp   
wc   
shuf   

Written in BASH, but may work okay with other shell variants. I haven't tested it.