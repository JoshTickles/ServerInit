#!/bin/bash/sh
#
# Requires Ubuntu distribution - This should work fine on versions 16.04 and below...	
#
#
currentver="0.62"
currentverdate="1sh July 2016"

WhichDistAmI()
{
	# Check for Ubuntu - This should work fine on versions 16.04 and below...	
	if [ -f "/usr/bin/lsb_release" ];
	then
		ubuntuVersion=`lsb_release -s -d`

		case $ubuntuVersion in
			*"Ubuntu"*)
				OS="Ubuntu"
				export OS
			;;

			*)
				echo -e "Script is for Ubuntu OS only. Exiting."
				exit 1
			;;
		esac
	fi
}

AmIroot()
{
	# Check for root, quit if not present with a warning.
	if [ "$(id -u)" != "0" ];
	then
		echo "\nScript needs to be run as root. Please elevate and run again!"
		exit 1
	else
		echo "\nScript running as root. Starting..."
	fi
}

Update()
{
	echo 
	echo "Updating repositories ..."
		apt-get -qq -y update
	echo 
	echo "Upgrading installed packages as required..."
		apt-get -qq -y upgrade
}

#------------------ PKG Install Functions ------------------------
InstallFirewall()
{
	# Is UFW installed?
	ufw=$(dpkg -l | grep "ufw" >/dev/null && echo "yes" || echo "no")

		if [ $ufw = "no" ];
		then
			echo "\nufw not installed. Installing now...\n"
			apt-get install -q -y ufw
			ufw enable
		else
			echo "\nufw already installed..."
		fi
}

ConfigFW()
{	# Is UFW installed?
	ufw=$(dpkg -l | grep "ufw" >/dev/null && echo "y" || echo "n")
		if [ $ufw = "n" ];
		then
			echo "\nufw not installed. Please install it first."
		else
			echo "\nufw already installed. Proceeding."
			ufw --force disable		# Disables the firewall before we make our changes
			#ufw --force reset		# Resets any firewall rules
			wfw allow ssh			# Port 22
			ufw allow http			# Port 80 
			ufw allow smtp			# Port 25
			ufw allow ntp			# Port 123
			ufw allow https			# Port 443
			ufw allow http-alt		# Port 8080
			ufw --force enable		# Turns on the firewall. May cause ssh disruption in the process.
			sleep 2
			ufw status
		sleep 5
		fi

}

InstallOpenVMTools()
{
	# Are the open-vm-tools installed?
	openvmtools=$(dpkg -l | grep "open-vm-tools" >/dev/null && echo "y" || echo "n")

		if [ $openvmtools = "n" ];
		then
			echo "\nopen vm tools not installed. Installing now..."

			echo "\nGetting VMware packaging keys from server."
			wget http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub
			wget http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub

			echo "\nInstalling VMware packaging keys into apt."
			apt-key add ./VMWARE-PACKAGING-GPG-DSA-KEY.pub
			apt-key add ./VMWARE-PACKAGING-GPG-RSA-KEY.pub

			echo "\nCleaning up key files."
			rm ./VMWARE-PACKAGING-GPG-DSA-KEY.pub
			rm ./VMWARE-PACKAGING-GPG-RSA-KEY.pub

			echo "\nInstalling open vm tools."
			apt-get install -q -y open-vm-tools
		else
			echo "\nopen vm tools already installed..."
		fi		
}

InstallGit()
{
	git=$(dpkg -l | grep "git" >/dev/null && echo "y" || echo "n")
	
		if [ $git = "n" ];
		then
			echo "\n Git is not installed. Installing now..."
			apt-get install -y git
		else
			echo ""
			echo "Git is already installed..."
		fi
}

InstallNetdata()
{
#Check to see if Git is installed yet.
	git=$(dpkg -l | grep "ufw" >/dev/null && echo "y" || echo "n")
		if [ $git = "n" ];
		then
			echo "\n Git is not installed. Installing now..."
			sleep 1
			apt-get install -y git
		else
			echo ""
			echo "Git is already installed..."
			sleep 1
# Start with getting dependancies.
	echo "\nGetting dependencies..."
	apt-get -y -qq install zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autogen automake pkg-config
	sleep 3
	echo "\nDependencies have been installed... Installing Netdata"
# Change to home folder as I can't get git to clone to a specific folder... 
	sleep 2
# Now install Netdata...
	git clone https://github.com/firehol/netdata.git --depth=1 /home/$USER/netdata
	sleep 5
	echo "\nRepo has been cloned... Now to run install script..."
	sleep 2
	/home/$USER/netdata/netdata-installer.sh --dont-wait
	echo "\n Netdata is cloned and running. I'll check the port is open now..."
	sleep 3
	# stop netdata
		killall netdata

	# copy netdata.service to systemd
		cp system/netdata.service /etc/systemd/system/

	# let systemd know there is a new service
		systemctl daemon-reload

	# enable netdata at boot
		systemctl enable netdata

	# start netdata
		service netdata start
fi
}

FWNetData()
{
# Is UFW installed?
	ufw=$(dpkg -l | grep "ufw" >/dev/null && echo "y" || echo "n")
		if [ $ufw = "n" ];
		then
			echo "\nufw not installed. Bypassing..."
		else
			echo "\nufw already installed. Adding the rules...."
			sleep 1
			#Now open port 19999
			ufw allow 19999
			echo "\nPort 19999 is open, Here's the current Port list..."
			ufw status
			sleep 3
		fi
}

InstallOpenSSH()
{
	ssh=$(dpkg -l | grep "openssh-server" >/dev/null && echo "y" || echo "n")
	
		if [ $ssh = "n" ];
		then
			echo "\nOpenssh-server is not installed. Installing now..."
			apt-get install -qq -y openssh-server
		else
			echo "\nOpenssh-server is already installed..."
			
		fi
 }
 
SetAlias()
 {
 	#Grab username 
 	echo "Please enter your account username for alias binding: "
		read Username
	echo "You entered: $Username"
	sleep 3
	echo "Applying aliases to $Username's profile..."
 	sleep 3
 		save="/home/$Username/.bash_aliases"
 	echo "" >> $save #Create New line in .bash_aliases
 	echo "## Aliases set by 'ServerInit' script" >> $save
 	echo "alias dist-upgrade='sudo apt-get dist-upgrade'" >> $save
 	echo "alias upgrade='sudo apt-get upgrade'" >> $save
 	echo "alias update='sudo apt-get update'" >> $save
 	echo "alias c='clear'" >> $save
 	# Add any more Alias' you wish...
 	sleep 3
 	echo "Aliases have been added... You must exit your session for these to take effect."
 }
 
Installmolly()
{
	git=$(dpkg -l | grep "molly-guard" >/dev/null && echo "y" || echo "n")
	
		if [ $git = "n" ];
		then
			echo "\n Molly-Guard is not installed. Installing now..."
			apt-get install -y molly-guard
		else
			echo ""
			echo "Molly-Guard is already installed..."
		fi
}

hosts()
 {	#
	echo "\nThis will add entries to the hosts file for the home network..."
	sleep 2
	echo "\nThe domain will be .home.lan"
	sleep 2
	read -p "\nDo you wish to continue? [y/n]" ans
		if [ "$ans" = "y" ]; 
			then 
		echo "" >> /etc/hosts	
		echo "# Networking Services" >> /etc/hosts	
		echo "10.0.1.5	pfsense pfsense.home.lan" >> /etc/hosts
		echo "10.0.1.5	fw fw.home.lan" >> /etc/hosts
		echo "10.0.1.6	esxi1 esxi1.home.lan" >> /etc/hosts
		echo "10.0.1.7	pi-hole pi-hole.home.lan" >> /etc/hosts
		echo "10.0.1.7	dns dns.home.lan" >> /etc/hosts
		echo "10.0.1.10	router router.home.lan" >> /etc/hosts
		echo "10.0.1.10	rt rt.home.lan" >> /etc/hosts
		echo "" >> /etc/hosts	
		echo "# Servers / Devices" >> /etc/hosts
		echo "10.0.1.20	tv tv.home.lan" >> /etc/hosts
		echo "10.0.1.20	plex plex.home.lan" >> /etc/hosts
		echo "10.0.1.20	movies movies.home.lan" >> /etc/hosts
		echo "10.0.1.21	dll dll.home.lan" >> /etc/hosts
		echo "10.0.1.21	nzbget nzbget.home.lan" >> /etc/hosts
		sleep 2
		echo "Process done. Would you like me to restart the dnsmasq service? [y/n]" ans
				if [ "$ans" = "y" ]; 
					then 
						service dnsmasq restart
					else 
						echo "Returning to menu"
				fi
			else
		echo "\nReturning to main menu..."
		fi 
} 


#----------------------------- Other functions
InitialiseServer()
#List all Install Functions in here...
 {
Update
InstallGit
InstallOpenSSH
InstallOpenVMTools
 }

Networking()
{
	echo "Please enter your Networking information...Some fields are pre-populated for you"
	echo "\nCtrl + X when finished to save your changes."
	sleep 3
	echo "\naddress " >> /etc/network/interfaces
	echo "netmask " >> /etc/network/interfaces
	echo "gateway " >> /etc/network/interfaces
	echo "dns-nameservers " >> /etc/network/interfaces
	sleep 1
	sudoedit /etc/network/interfaces
	echo "\nNow maybe a good time to restart your network interface..."
}

NetworkingRestart()
{ 
read -p "Warning - this will restart your networking interface... Are you sure you wish to do this? (y/n)" ans
if [ "$ans" = "y" ]; 
	then
  		ifdown --exclude=lo -a && sudo ifup --exclude=lo -a
	else
  echo "\nReturning to main menu..."
fi
}

#------------------------------------- Menu's

MainMenu()
{
# Set IFS to only use new lines as field separator.
IFS=$'\n'

# Clear Screen
	clear

# Start menu here
	echo  "----------------------------------------"
	echo  "          Server init script"
	echo  "----------------------------------------"
	echo  "  Version $currentver - $currentverdate"
	echo  "----------------------------------------"
	echo

choice=""
while [ "$choice" != "q" ]
do
	echo
	echo  "----------------------"
	echo  "Setup Menu"
	echo  "----------------------"
	echo  "1) Update Package lists and upgrade as required"
	echo  "2) Install all the default software"
	echo  "3) Setup network configuration"
	echo  "4) Restart network interfaces"
	echo  "5) Setup common system Aliases"
	echo  "6) empty"
	echo  "7) "
	echo  "8) Nope."
	echo  "9) Specific package install and configuration..."
	echo  "q) Exit "
	echo 
	
	read -p "Pick a option: " choice

	case "$choice" in
		'1') Update ;;
		
		'2') InitialiseServer ;;
		
		'3') Networking ;;
		
		'4') NetworkingRestart ;;
		
		'5') SetAlias ;;
		
		'6') echo "empty" ;;
		
		'7') xyz ;;
			
		'8') hosts ;;
			
		'9') PkgMenu	;;
		
		q) echo "\nExiting the script. "
			;;
		*) echo "\nBad input. Please try again." ;;
	esac
done
}

PkgMenu()
{
# Set IFS to only use new lines as field separator.
	IFS=$'\n'
# Clear the screen
	clear
choice=""
while [ "$choice" != "q" ]
do
	echo
	echo  "----------------------"
	echo  " Package Menu"
	echo  "----------------------"
	echo  "1) Update Package lists and upgrade as required"
	echo  "2) Install Open VM Tools"
	echo  "3) Install UFW Firewall"
	echo  "4) Configure UFW Firewall"
	echo  "5) Install Molly-Guard"
	echo  "6) "
	echo  "7) Install Netdata"
	echo  "8) Install OpenSSH Server"
	echo  "9) Return to Main Menu"
	echo  "q) Exit"
	echo 
	
	read -p "Pick a option: " choice

	case "$choice" in
		'1') Update ;;
		
		'2') InstallOpenVMTools ;;
		
		'3') InstallFirewall ;;
		
		'4') ConfigFW ;;
		
		'5') Installmolly ;;
		
		'6') echo "empty" ;;
		
		'7') InstallNetdata
			FWNetData
			echo "\nNetData installed. It's on Port 19999" ;;
			
		'8') InstallOpenSSH ;;
			
		'9') MainMenu	;;
		
		q) echo "\nExiting the script. "
			;;
		*) echo "\nBad input. Please try again." ;;
	esac
done
}

#-------------------------------------------- Main Code Begins here!

# Check for distribution, root and start the menu

# WhichDistAmI
AmIroot
MainMenu

exit 0
