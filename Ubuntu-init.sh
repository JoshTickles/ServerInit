#!/bin/bash
#
# Requires Ubuntu distribution - This should work fine on versions 16.04 and below...	
#
#
currentver="0.1"
currentverdate="8th June 2016"

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
		echo -e "Script needs to be run as root. Please elevate and run again!"
		exit 1
	else
		echo -e "Script running as root. Starting..."
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
			echo -e "\nufw not installed. Installing now...\n"
			apt-get install -q -y ufw
		else
			echo -e "\nufw already installed. Proceeding."
		fi

}

InstallOpenVMTools()
{
	# Are the open-vm-tools installed?
	openvmtools=$(dpkg -l | grep "open-vm-tools" >/dev/null && echo "yes" || echo "no")

		if [ $openvmtools = "no" ];
		then
			echo -e "\nopen vm tools not installed. Installing now..."

			echo -e "\nGetting VMware packaging keys from server."
			wget http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub
			wget http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub

			echo -e "\nInstalling VMware packaging keys into apt."
			apt-key add ./VMWARE-PACKAGING-GPG-DSA-KEY.pub
			apt-key add ./VMWARE-PACKAGING-GPG-RSA-KEY.pub

			echo -e "\nCleaning up key files."
			rm ./VMWARE-PACKAGING-GPG-DSA-KEY.pub
			rm ./VMWARE-PACKAGING-GPG-RSA-KEY.pub

			echo -e "\nInstalling open vm tools."
			apt-get install -q -y open-vm-tools
		else
			echo -e "\nopen vm tools already installed. Proceeding."
		fi		
}

InstallGit()
{
	git=$(dpkg -l | grep "git" >/dev/null && echo "y" || echo "n")
	
		if [ $git = "n" ]:
		then
			echo -e "\n Git is not installed. Installing now..."
			apt-get install -y git
		else
			echo ""
			echo "Git is already installed. Proceeding."
		fi
}


InstallNetdata()
{
#Check to see if Git is installed yet.
	git=$(dpkg -l | grep "ufw" >/dev/null && echo "y" || echo "n")
		if [ $git = "n" ]:
		then
			echo "\n Git is not installed. Installing now..."
			sleep 1
			apt-get install -y git
		else
			echo ""
			echo "Git is already installed. Proceeding."
			sleep 1
# Start with getting dependancies.
	echo "/nGetting dependencies..."
	apt-get -y -qq install zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autogen automake pkg-config
	sleep 3
	echo "/nDependencies have been installed... Installing Netdata"
# Change to home folder as I can't get git to clone to a specific folder... 
	sleep 2
# Now install Netdata...
	git clone https://github.com/firehol/netdata.git --depth=1 /home/$USER/netdata
	sleep 5
	echo "\nRepo has been cloned... Now to run install script..."
	sleep 2
	/home/$USER/netdata/netdata-installer-sh --dont-wait
	echo "\n Netdata is installed and running. I'll check the port is open now..."
	sleep 3
fi
}
FWNetData()
{
# Is UFW installed?
	ufw=$(dpkg -l | grep "ufw" >/dev/null && echo "y" || echo "n")
		if [ $ufw = "n" ];
		then
			echo "\nufw not installed. Bypassing...\n"
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
	
		if [ $ssh = "n" ]:
		then
			echo "\nOpenssh-server is not installed. Installing now..."
			apt-get install -qq -y openssh-server
		else
			echo "\nOpenssh-server is already installed..."
			echo
		fi
 }




InitialiseServer ()
#List all Install Functions in here...
{
Update
InstallGit
InstallOpenSSH
InstallOpenVMTools
}









#------------------------------------- Menu's

MainMenu()
{
# Set IFS to only use new lines as field separator.
IFS=$'\n'

# Clear Screen
	clear

# Start menu screen here
	echo  "----------------------------------------"
	echo  "          Server init script"
	echo  "----------------------------------------"
	echo  "  Version $currentver - $currentverdate"
	echo  "----------------------------------------"
choice=""
while [ "$choice" != "q" ]
do
	echo  "----------------------"
	echo  "Setup Menu"
	echo  "----------------------"
	echo  "1) Update Package lists and upgrade as required"
	echo  "2) Install all the default software"
	echo  "3) "
	echo  "4) "
	echo  "5) "
	echo  "6) "
	echo  "7) Install Netdata for monitoring"
	echo  "8) Install OpenSSH Server"
	echo  "9) Specific package install and configuration..."
	echo  "q) Exit Script"
	echo 
	
	read -p "Pick a option: " choice

	case "$choice" in
		'1') Update ;;
		
		'2') InitialiseServer ;;
		
		'3') echo "\nempty" ;;
		
		'4') echo "empty" ;;
		
		'5') echo "empty" ;;
		
		'6') echo "empty" ;;
		
		'7') InstallNetdata
			FWNetData
			echo
			echo "NetData installed. It's on Port 19999" ;;
			
		'8') InstallOpenSSH ;;
			
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

# Start menu screen here
	echo -e "\n----------------------------------------"
	echo -e "\n       Ubuntu Server init script"
	echo -e "\n----------------------------------------"
	echo -e "      Package Installation and Config"
	echo -e "----------------------------------------\n"


}


#-------------------------------------------- Main Code Begins here!

# Check for distribution, root and start the menu

WhichDistAmI
AmIroot
MainMenu

exit 0

