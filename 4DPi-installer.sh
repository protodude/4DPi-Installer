#!/bin/sh


INTERACTIVE=True
ASK_TO_REBOOT=0




do_install(){

whiptail --yesno "Would you like Install the Kernel Package?" 20 60 2 \
    --yes-button Yes --no-button No
  RET=$?
  if [ $RET -eq 0 ]; then
        #Download and install kernel pack 
		sudo wget http://www.4dsystems.com.au/downloads/4DPi/4DPi-24-HAT/4DPi-24-HAT_kernel_R_1_0.tar.gz &&
        sudo tar -xzvf 4DPi-24-HAT_kernel_R_1_0.tar.gz -C / &&
		sudo apt-get -y  install libx11-dev libxext-dev libxi-dev x11proto-input-dev
		#Set standard values to cmdline.txt
		sudo sed -i 's/$/ 4dpi.compress=7 4dpi.sclk=48000000 4dpi.rotate=0 /' /boot/cmdline.txt
		#Download and install Xinput_calibrator
		sudo wget http://github.com/downloads/tias/xinput_calibrator/xinput_calibrator-0.7.5.tar.gz
        sudo tar -xzvf xinput_calibrator-0.7.5.tar.gz
		cd xinput_calibrator-0.7.5
		./configure
		make
		sudo make install
		# Remove installation files
		 sudo rm xinput_calibrator-0.7.5.tar.gz
		 sudo rm -rf xinput_calibrator-0.7.5
		 sudo rm -rf 4DPi-24-HAT_kernel_*.tar.gz	
		whiptail --msgbox "Install Complete" 20 60 1
		# Select Hardware
		whiptail --yesno "Do you use Raspberry Pi 2?" 20 60 2 \
		--yes-button Yes --no-button No
		RET=$?
		if [ $RET -eq 0 ]; then
		sudo sed -i 's/kernel=kernel.*_hat.img/kernel=kernel7_hat.img/g' /boot/config.txt
		whiptail --msgbox "Raspberry Pi set as Version 2" 20 60 1
		return 0

		elif [ $RET -eq 1 ]; then
		sudo sed -i 's/kernel=kernel.*_hat.img/kernel=kernel_hat.img/g' /boot/config.txt
		whiptail --msgbox "Raspberry Pi set as Version 1" 20 60 1
		return 0
		else
		return $RET
		fi
		# Boot to GUI?
		whiptail --yesno "Would you like to boot directly into GUI?" 20 60 2 \
		--yes-button Yes --no-button No
		RET=$?
		if [ $RET -eq 0 ]; then
		sudo sed -i -e '$i \sudo -u pi FRAMEBUFFER=/dev/fb1 startx &\n' /etc/rc.local &&
		whiptail --msgbox "Boot to GUI enabled" 20 60 1
		return 0
		elif [ $RET -eq 1 ]; then
		sudo sed -i '/sudo -u pi FRAMEBUFFER=/d' /etc/rc.local
		whiptail --msgbox "Boot to console" 20 60 1
		return 0
		else
		return $RET
		fi
		# Shutdown and plug in 4DPi
		whiptail --title "Shutdown NOW" --msgbox "The Pi will shutdown now. When Pi is OFF please remove the power cable and plugin your 4DPi and apply power." 8 78
		sudo shutdown now
	
	return 0
  elif [ $RET -eq 1 ]; then
    whiptail --msgbox "Install Canceled" 20 60 1
    return 0
  else
    return $RET
  fi
}

do_bootoption(){
whiptail --yesno "Would you like to boot directly into GUI?" 20 60 2 \
     --yes-button Yes --no-button No
     RET=$?
if [ $RET -eq 0 ]; then
    sudo sed -i -e '$i \sudo -u pi FRAMEBUFFER=/dev/fb1 startx &\n' /etc/rc.local &&
    whiptail --msgbox "Boot to GUI enabled" 20 60 1
return 0
  elif [ $RET -eq 1 ]; then
    sudo sed -i '/sudo -u pi FRAMEBUFFER=/d' /etc/rc.local
    whiptail --msgbox "Boot to console" 20 60 1
    return 0
  else
    return $RET
  fi
}




do_rotate() {

ROTATION=$(whiptail --title "Choose orientation preset" --menu "From which orientation do you want to view the screen?" 20 60 10 \
    " 1 " "Standard orientation" \
    " 2 " "90° right from standard" \
    " 3 " "180° right from standard" \
    " 4 " "270° right from standard" 3>&1 1>&2 2>&3)

if [$ROTATION = 1 ]; then
    sudo sed -i 's/4dpi.rotate=.*/4dpi.rotate=0/g' /boot/cmdline.txt &&
    whiptail --msgbox "Rotate to Standard angle Complete - takes effect after next reboot" 20 60 1
    return 0
elif [$ROTATION = 2 ]; then
    sudo sed -i 's/4dpi.rotate=.*/4dpi.rotate=90/g' /boot/cmdline.txt &&
    whiptail --msgbox "Rotate to 90° Complete - takes effect after next reboot" 20 60 1
    return 0
elif [$ROTATION = 3 ]; then
    sudo sed -i 's/4dpi.rotate=.*/4dpi.rotate=180/g' /boot/cmdline.txt &&
    whiptail --msgbox "Rotate to 180° Complete - takes effect after next reboot" 20 60 1
    return 0
elif [$ROTATION = 4 ]; then
    sudo sed -i 's/4dpi.rotate=.*/4dpi.rotate=270/g' /boot/cmdline.txt &&
    whiptail --msgbox "Rotate to 270° Complete - takes effect after next reboot" 20 60 1
    return 0

else
   return $RET
fi
}



do_selecthw(){

whiptail --yesno "Do you use Raspberry Pi 2?" 20 60 2 \
     --yes-button Yes --no-button No
     RET=$?
if [ $RET -eq 0 ]; then
    sudo sed -i 's/kernel=kernel.*_hat.img/kernel=kernel7_hat.img/g' /boot/config.txt
    whiptail --msgbox "Raspberry Pi set as Version 2" 20 60 1
    return 0

  elif [ $RET -eq 1 ]; then
    sudo sed -i 's/kernel=kernel.*_hat.img/kernel=kernel_hat.img/g' /boot/config.txt
    whiptail --msgbox "Raspberry Pi set as Version 1" 20 60 1
    return 0
  else
    return $RET
  fi
}




do_about() {
whiptail --msgbox "\
This tool provides a straight-forward way of doing initial
configuration of the 4DPi-24-HAT on Raspberry Pi. \
" 20 70 1
}



do_calibrate() {
sudo mkdir -p /etc/X11/xorg.conf.d
sudo rm /etc/X11/xorg.conf.d/99-calibration.conf
DISPLAY=:0.0 xinput_calibrator --output-type xorg.conf.d > tempcal.txt
sudo sed -n '12,16 p' tempcal.txt > 99-calibration.conf
sudo cp 99-calibration.conf /etc/X11/xorg.conf.d/
}




do_finish() {
   disable_raspi_config_at_boot
   if [ $ASK_TO_REBOOT -eq 1 ]; then
     whiptail --yesno "Would you like to reboot now?" 20 60 2
     if [ $? -eq 0 ]; then # yes
       sync
      reboot
     fi
   fi
   exit 0
}



calc_wt_size() {
   # NOTE: it's tempting to redirect stderr to /dev/null, so supress error
   # output from tput. However in this case, tput detects neither stdout or
   # stderr is a tty and so only gives default 80, 24 values
   WT_HEIGHT=17
   WT_WIDTH=$(tput cols)


   if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
     WT_WIDTH=80
   fi
   if [ "$WT_WIDTH" -gt 178 ]; then
     WT_WIDTH=120
   fi
   WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}




#
# Interactive use loop
#
 calc_wt_size
 while true; do
   FUN=$(whiptail --title "4DPi-24-HAT Installer" --menu "Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
     "1 Download and Install Kernel Package" "Only do this once" \
     "2 Change Display Orientation" "Decide which orientation is used" \
     "3 Booting the Raspberry Pi directly to Desktop GUI" "Choose whether to boot into a desktop environment or the command-line" \
     "4 Select your Raspberry Pi Hardware Version" "Change Kernel Image" \
     "5 Calibrate Touch Screen" "Lets you Calibrate the touch screen" \
     "6 About" "About us" \
     3>&1 1>&2 2>&3)
   RET=$?
   if [ $RET -eq 1 ]; then
     do_finish
   elif [ $RET -eq 0 ]; then
     case "$FUN" in
       1\ *) do_install ;;
       2\ *) do_rotate ;;
       3\ *) do_bootoption ;;
       4\ *) do_selecthw ;;
       5\ *) do_calibrate ;;
       6\ *) do_about ;;
          *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
     esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
   else
     exit 1
   fi
 done

