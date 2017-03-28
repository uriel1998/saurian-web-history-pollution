#!/bin/bash

# Requires 
# awk
# sed
# head / tail
# grep
# curl

########################################################################
# Declarations
########################################################################

declare SpiderUrl
declare ListOfUrls
declare UrlToSpider
declare UAString
TempDir=$(mktemp -d)
UserAgents=$TempDir/UAStrings


##############################################################################
# Writing UA String Tempfile
###############################################################################
write_uafile(){
	# Add other strings here as you like. 
	echo "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36" > $UserAgents
	echo "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0) like Gecko" >> $UserAgents 
	echo "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1" >> $UserAgents
	echo "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" >> $UserAgents
	echo "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A" >> $UserAgents
	echo "Opera/9.80 (X11; Linux i686; Ubuntu/14.10) Presto/2.12.388 Version/12.16" >> $UserAgents
	echo "Opera/9.80 (Windows NT 6.0) Presto/2.12.388 Version/12.14" >> $UserAgents
	echo "Mozilla/5.0 (Linux; U; Android 4.0.3; ko-kr; LG-L160L Build/IML74K) AppleWebkit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30" >> $UserAgents
	echo "Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0)" >> $UserAgents
	echo "Opera/9.80 (J2ME/MIDP; Opera Mini/9.80 (J2ME/23.377; U; en) Presto/2.5.25 Version/10.54" >> $UserAgents
}

##############################################################################
# Getting the UA String
###############################################################################
get_uastring(){

	ualines=1
	uareadthisline=1
	
	ualines=$(wc -l < "$UserAgents")
	uareadthisline=$(shuf -i 1-$ualines -n 1)
	UAString=$(head -n $uareadthisline "$UserAgents" | tail -1)
	echo "Using $UAString"
	
}

##############################################################################
# Getting the URL to spider and making sure it doesn't redirect
###############################################################################
get_url_to_spider() {
	lines=1
	readthisline=1
	declare url
	
	lines=$(wc -l < "$ListOfUrls")
	readthisline=$(shuf -i 1-$lines -n 1)
	url=$(head -n $readthisline "$ListOfUrls" | tail -1)
	get_uastring
	UrlToSpider=$(curl -H "$UAString" $url -s -L -I -o /dev/null -w '%{url_effective}')
	echo "We're going to crawl $UrlToSpider"
	
}

##############################################################################
# Spidering the URL and catching all the new links from it
###############################################################################
spider_url() {
	
	baseurl=$(echo "$UrlToSpider" | awk -F/ '{print $3}')
	# echo "$baseurl"
	# First grep cuts out links
	# First cut trims it up
	# Second grep cuts out filetypes we don't want
	# First sed expression catches return urls without http:// prefix. 
	# Second sed expression catches relative urls, prefixes base url
	# Third and fourth grep expression catches wierd skype, mailto, etc links
	# Last two cut out all the extra wikipedia/wikimedia links we don't need
	# To force it to look outside wikipedia
	curl -H "$UAString" "$UrlToSpider" 2>&1 | grep -o -E 'href="([^"#]+)"' | cut -d'"' -f2 | grep -v '\.\(css\|js\|png\|gif\|jpg\|ico\|jpeg\|pdf\)$' | sed '/^\/\//s#//#http://#' | sed "/^\//s#/#$baseurl/#" | grep '^http' | grep -v 'action=' | grep -v 'wikipedia' | grep -v 'wikimedia' > $TempDir/RawUrls

}


##############################################################################
# Removing duplicates with our little saurian arms
###############################################################################
saurian_url() {

	numurls=$(wc -l < "$TempDir/RawUrls")
	echo "There were $numurls gotten from that link..."
	
	# This needs to be optimized and cut down; sorting a 30 MB list of urls
	# is just insane
	sort $TempDir/RawUrls | uniq > $TempDir/BigUrls.merged
	sort $ListOfUrls | uniq >> $TempDir/BigUrls.merged
	sort $TempDir/BigUrls.merged | awk '/^http:/'  | awk 'length($0) < 120' | grep -v -e "twitter" -e ".facebook" -e "doubleclick" -e "adserver" | uniq | shuf > $TempDir/BigUrls.sorted
	head -n 10000 $TempDir/BigUrls.sorted > $ListOfUrls


	# cleaning up after ourselves
	rm $TempDir/RawUrls
	rm $TempDir/BigUrls.sorted
	rm $TempDir/BigUrls.merged

}

###############################################################################
# The actual loop of the program
###############################################################################

main() {


	increment=0
		
	while :
		do
			get_url_to_spider
			spider_url
			saurian_url
			numurls=$(wc -l < "$ListOfUrls")
			(( ++increment ))
			interval=$(shuf -i 1-30 -n 1)
			echo "$increment URLs crawled."
			echo "$numurls URLs in list."
			echo "Waiting $interval seconds."
			echo "Press [CTRL+C] to stop.."			
			sleep $interval
		done
}


###############################################################################
# Startup Sanity Checker
###############################################################################

echo "Welcome to Saurian Spider, your friendly web history obfuscator!"


if [ ! -f "$1" ];then
	if [ ! -f "$HOME/.config/saurianspider.conf" ];then
		echo "Initializing list of URLs at $HOME/.config/saurianspider.conf"
		echo "https://en.wikipedia.org/wiki/Special:Randompage" > $HOME/.config/saurianspider.conf
		echo "https://en.wikipedia.org/wiki/Portal:Current_events" >> $HOME/.config/saurianspider.conf
	fi
	echo "Using list of URLs at $HOME/.config/saurianspider.conf"	
	ListOfUrls="$HOME/.config/saurianspider.conf"
else
	echo "Utilizing your list of URLs at $1"
	ListOfUrls="$1"
fi

###############################################################################
# Let's do it!
###############################################################################

write_uafile
main
