#!/bin/bash

version="0.1"

# Activate Chia Environment
appdir=`pwd`
cd ~/chia-blockchain
. ./activate
cd $appdir

# define some colors
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
bldgrn='\e[1;32m' # Bold Green
bldpur='\e[1;35m' # Bold Purple
txtrst='\e[0m' # Text Reset

mojo2xch()
{
    local mojo=$1
    local xch=""

    # cant do floating division in Bash but we know xch is always mojo/10000000000
    # so we can use string manipulation to build the xch value from mojo
    mojolength=`expr length $mojo`
    if [ $mojolength -eq 12 ]; then
        xch="0.$mojo"
    elif [ $mojolength -lt 12 ]; then
        temp=`printf "%012d" $mojo`
        xch="0.$temp"
    else
        off=$(($mojolength - 12))
        off2=$(($off + 1))
        temp1=`echo $mojo | cut -c1-$off`
        temp2=`echo $mojo | cut -c$off2-$mojolength`
        xch="$temp1.$temp2"
    fi
    echo "$xch"
}

sleep_countdown()
{
	secs=$(($1))
	while [ $secs -gt 0 ]; do
		echo -ne " $secs\033[OK\r"
		sleep 1
		: $((secs--))
	done
}

display_banner()
{
	echo -e "${bldgrn}"
	echo -e "    ██████╗ ███████╗███████╗███████╗██████╗         ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗"
	echo -e "   ██╔═══██╗██╔════╝██╔════╝██╔════╝██╔══██╗        ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝"
	echo -e "   ██║   ██║█████╗  █████╗  █████╗  ██████╔╝        ███████╗██║     ██████╔╝██║██████╔╝   ██║   "
	echo -e "   ██║   ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██╗        ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   "
	echo -e "   ╚██████╔╝██║     ██║     ███████╗██║  ██║███████╗███████║╚██████╗██║  ██║██║██║        ██║   "
	echo -e "    ╚═════╝ ╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   "
	echo -e " ------------------------------------------------------------${txtred}"
	echo -e " Interactive script                                       $version${bldgrn}"
	echo -e " ------------------------------------------------------------"
}

menu()
{
	echo ""
	echo " 1. Create NFT list for Collection"
	echo " 2. Create Offers from NFT list"
	echo ""
	read -p " Selection: " menu_selection

	###########################################################
	# Exit menu
	###########################################################
	if [ "$menu_selection" == "X" ] || [ "$menu_selection" == "x" ] || [ "$menu_selection" == "" ]; then
		echo ""
		exit
	fi

	###########################################################
	# 1. Create NFT list of colleciton
	###########################################################
	if [ "$menu_selection" == "1" ]; then
		echo ""
		echo -e " You will need the Collection ID. You can find this on    ${txtrst}https://mintgarden.io${bldgrn}"
		echo -e ""
		echo -e " Search for your collection name ie. Marmot Boxes which should result in a page with a URL like such:"
		echo -e "   ${txtrst}https://mintgarden.io/collections/astrobots-col10en0hus79683c372nux50ev7smv5amrj9tjggkpandhqxd9pnlssmp2uwl${bldgrn}"
		echo -e ""
		echo -e " You Collection ID is everything after the hyphen in the URL."
		echo -e " For example:   ${txtrst}col10en0hus79683c372nux50ev7smv5amrj9tjggkpandhqxd9pnlssmp2uwl${bldgrn}"
		echo -e ""
		read -p " Collection ID? " collection_id

		echo ""
		read -p " Output to Screen or File S/F? " output_type
		if [ "$output_type" == "F" ] || [ "$output_type" == "f" ]; then
			read -p " Filename to save as? " outfile
			if [ -f "$outfile" ]; then
				rm $outfile
				touch $outfile
			fi
		fi
		if [ "$collection_id" != "X" ] && [ "$collection_id" != "x" ]; then
			nfts=`curl -s https://api.mintgarden.io/collections/$collection_id/nfts/ids`
			echo -e "${txtrst}"
			nft_list=`echo "$nfts" | jq '.[].encoded_id' | cut --fields 2 --delimiter=\"`
			for id in $nft_list; do
				#outputting to the console screen slows the script down
				if [ "$output_type" == "S" ] || [ "$output_type" == "s" ]; then
					echo -e "${txtrst}$id${bldgrn}"
				fi
				if [ "$output_type" == "F" ] || [ "$output_type" == "f" ]; then
					echo "$id" >> $appdir/$outfile
				fi
			done
			echo -e "${bldgrn}"
		fi
	fi

	###########################################################
	# 2. Create Offers from NFT list
	###########################################################
	if [ "$menu_selection" == "2" ]; then

		script_type=""
		local fingerprint=$(get_fingerprint)

		echo -e ""
		read -p " Will all offers be the same price [Y]es or [N]o? " same_price
		echo -e ""
		read -p " [Enter] to Execute offer commands or [B] to Build offer command script? " script_type
		echo -e ""
		read -p " Directory to save offers? [will created a subfolder if it doesn't exist] " savepath
		mkdir -p $appdir/$savepath

		if [ "$script_type" == "b" ] || [ "$script_type" == "B" ]; then
			echo -e ""
			read -p " Name for script to create offers? " script_name
			echo "#!/bin/bash" > $appdir/$savepath/$script_name
			echo "" >> $appdir/$savepath/$script_name
		fi

		echo -e ""
		read -p " Amount of seconds between commands? " wait_secs
		sleep_cmd="sleep $wait_secs"

		# create the files directory if it doesn't exist
		mkdir -p files

		if [ "$same_price" == "Y" ] || [ "$same_price" == "y" ]; then
			echo -e ""
			read -p " Offer price in XCH? " price
			echo -e ""
			echo -e " The input file should be a list of NFT IDS. One on each line. Any text after the first 62"
			echo -e " characters on the line is ignored so you can include a description for each NFT after the id."
			echo -e ""
			echo -e " REQUIRED FILE FORMAT: NFT_ID is required. You can have other fields blank but do include the commas (3 commas total)."
			echo -e " NFT_ID,Name,Price,Events"
			echo -e ""
			echo -e " Example:"
			echo -e " nft1rd2jx4uc0qgrdrw0l3cj276q5jvl3u3n85ncpyt05aahfr7xw7gskngzsn,#21,0.4,2"
			echo -e ""
			read -p " Filename? " infile
			echo -e ""

			echo -e ""
			fee_mojos=""
			read -p " [Enter] for 1 mojo fee per offer, or specific number of mojos: " fee_mojos
			if [ "$fee_mojos" == "" ]; then
				fee_mojos="1"
			fi

			# convert fee_mojos to fee_xch
			fee_xch=$(mojo2xch $fee_mojos)

			echo ""
			if [ -f "$infile" ]; then

				while read line; do

					if [[ $line == *","* ]]; then
						nft_id=`echo "$line" | cut --fields 1 --delimiter=,`
						desc=`echo "$line" | cut --fields 2 --delimiter=,`
						temp=`echo "$line" | cut --fields 3 --delimiter=,`
						if [ "$temp" != "" ]; then
							price=$temp
						fi
						offer_name=`echo "$desc" | cut --fields 1 --delimiter=\ `
					else
						nft_id=`echo "$line" | cut -c 1-62`
						offer_name="$nft_id"
					fi

					cmd="yes | ~/chia-blockchain/venv/bin/chia wallet make_offer -f $fingerprint -m $fee_xch -o $nft_id:1 -r 1:$price -p $appdir/$savepath/$offer_name.offer"

					if [ "$script_type" == "" ]; then
						echo " cmd = $cmd"
						sleep_countdown $wait_secs
					elif [ "$script_type" == "b" ] || [ "$script_type" == "B" ]; then
						echo "$cmd && $sleep_cmd" >> $appdir/$savepath/$script_name
					fi

				done <$infile
			fi
		else
			echo -e ""
			echo -e " The input file should be a CSV file, with each NFT IDS and it's price on one line."
			echo -e " You can also have a comma after price and any description. The description will be ignored."
			echo ""
			read -p " Filename? " infile

			echo ""
			if [ -f "$infile" ]; then
				cat $infile
			fi
		fi

	fi

	echo ""
	read -p " Press [Enter] to continue... " keypress

	###########################################################
	# END OF MENU
	###########################################################
}

create_offers()
{
	local id=$1
	local price=$2

	echo "create offers"

}

get_fingerprint()
{
	fingerprint=`chia wallet show | grep "fingerprint:" | cut -c 24-`
	echo "$fingerprint"
}

###################
# MAIN
###################
while true
do
	clear
	display_banner
	menu
done

# set colors back to normal
echo -e "${txtrst}"

###################
# END
###################
