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
	if [[ "$(id -u)" != "0" ]];
	then
		echo -e "Script needs to be run as root. Please elevate and run again!"
		exit 1
	else
		echo -e "Script running as root. Starting..."
	fi
}

Update()
{
	echo ""
	echo "Updating apt-get repository ..."
		apt-get -qq -y update
	echo ""
	echo "Upgrading installed packages ..."
		apt-get -q -y upgrade
}

#------------------ PKG Install Functions ------------------------

InstallFirewall()
{
	# Is UFW installed?
	ufw=$(dpkg -l | grep "ufw" >/dev/null && echo "yes" || echo "no")

		if [[ $ufw = "no" ]];
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

		if [[ $openvmtools = "no" ]];
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
	
		if [[ $git = "n" ]]:
		then
			echo -e "\n Git is not installed. Installing now..."
			apt-get install -y git
		else
			echo ""
			echo "Git is already installed. Proceeding."
}


InstallNetdata()
{
#Check to see if Git is installed yet.
	git=$(dpkg -l | grep "ufw" >/dev/null && echo "y" || echo "n")
		if [[ $git = "n" ]]:
		then
			echo -e "\n Git is not installed. Installing now..."
			apt-get install -y git
		else
			echo ""
			echo "Git is already installed. Proceeding."
#Start with getting dependancies.
	echo -e "/nGetting dependencies..."
	apt-get -y -q install zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autogen automake pkg-config
	echo -e "/nDependencies have been installed... Installing Netdata"
#Now install Netdata...
	git clone https://github.com/firehol/netdata.git --depth=1
	echo -e "\nRepo has been cloned... Now to run install script..."
	~/netdata/netdata-installer-sh --dont-wait
	echo -e "\n Netdata is installed and running. I'll check the port is open now..."
# Is UFW installed?
	ufw=$(dpkg -l | grep "ufw" >/dev/null && echo "y" || echo "n")
		if [[ $ufw = "n" ]];
		then
			echo -e "\nufw not installed. Bypassing...\n"
		else
			echo -e "\nufw already installed. Proceeding."
			#Now open port 19999
			ufw allow 19999
			echo -e "\n Port 19999 has been opened, Here's the current Port list..."
			ufw status			
		fi
}

InstallOpenSSH()
{
	ssh=$(dpkg -l | grep "openssh-server" >/dev/null && echo "y" || echo "n")
	
		if [[ $ssh = "n" ]]:
		then
			echo -e "\nOpenssh-server is not installed. Installing now..."
			apt-get install -y openssh-server
		else
			echo -e "\nOpenssh-server is already installed. Proceeding."
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
	echo -e "\n----------------------------------------"
	echo -e "\n          Server init script"
	echo -e "\n----------------------------------------"
	echo -e "    Version $currentver - $currentverdate"
	echo -e "----------------------------------------\n"

while [[ $choice != "q" ]]
do
	echo -e "\nSetup Menu\n"
	echo -e "1) Update Package lists and upgrade as required"
	echo -e "2) Install all the default software"
	echo -e "3) "
	echo -e "4) "
	echo -e "5) "
	echo -e "6) "
	echo -e "7) Install Netdata for monitoring"
	echo -e "8) Install OpenSSH Server"
	echo -e "9) Specific package install and configuration..."
	echo -e "q) Exit Script\n"

	read -p "Pick a option (1-9 / q) : " choice

	case "$choice" in
		1)
			Update ;;
		2)
			InitialiseServer ;;
		3)
			 ;;
		4)
			DeleteInstance ;;
		5)
			DumpDatabase ;;
		6)
			UploadDatabase ;;
		7)
			InstallNetdata
			echo -e "\nNetData installed. It's on Port 19999" ;;
		8)
			InstallOpenSSH
			echo -e "\nOpenssh-server is installed. It's on the default port."	;;
		9)
			PkgMenu	;;
		q)
			echo ""
			echo "Exiting the script. "
			;;
		*)
			echo -e "\nIncorrect input. Please try again." ;;
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

# Check for distribution, user privilege level and required files

WhichDistAmI
AmIroot
MainMenu

exit 0
