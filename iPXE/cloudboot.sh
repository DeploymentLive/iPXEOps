#!ipxe

# Copyright Deployment Live LLC, All Rights Reserved

#region Initialization

set isca DeploymentLive CA
set ipxeServer ${cwduri}
set deploymnetliveBlob http://deploymentlivefiles.blob.core.windows.net/ipxebootfiles

if ( certstat -s ${isca} )

    set catype ca
    certstore Githubcross.crt ||
    set netbootxyz http://boot.netboot.xyz

else
    set catype full
    set netbootxyz https://boot.netboot.xyz

end if

# Automation here.

if ( isset ${deploymentlivemenu} )

    if ( NOT prompt --timeout 10000 Ready to run automation ${deploymentlivemenu} [10sec] ) 
        call ${deploymentlivemenu}
    end if

end if

#endregion

#region Main Menu

while ( isset ${version} )  # Always loop

    menu Cloud Ready Deployment and Recovery System

        item --gap
        item osdboot  ${fgyellow} Repair or Install ${fgdefault} ${} Windows Operating System  ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} [WinPE With OSDCloud]
        item --gap
        item linuxlive ${fgyellow} Run Backup Desktop ${fgdefault} Operating System ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} [Linux Ubuntu KDE LiveCD]
        item --gap
        item --gap
        item --gap
        item --gap
        item debug_shutdown ${fggreen} Shutdown ${fgdefault} Computer
        item debug_reboot ${fggreen} Reboot ${fgdefault} ${} ${} Computer
        item --default debug_continue ${fggreen} Continue ${fgdefault} Boot to Local Disk
        item --gap
        item --gap
        item --gap
        item main_tools ${fgyellow} Advanced Tools Menu ${fgdefault}...


    choose --timeout 300000 main_menu || set main_menu nothing
    if ( iseq ${main_menu} exit )
        exit  # Continue with boot
    end if

    if ( NOT iseq ${main_menu} nothing )
        call ${main_menu}
    end if
wend

sub osdboot

    set msftvm Virtual Machine
    set msft Microsoft Corporation

    if ( iseq ${efi/SecureBoot} 01 )
        if ( iseq ${manufacturer} ${msft} )
            if ( iseq ${product} ${msftvm} )

                echo
                echo  "Hello, and thanks for trying out Deployment Live's iPXE Live Cloud Ready Deployment and Recovery system."
                echo
                echo  We can see that you are running this on a Windows Hyper-V Virtual Machine. We like running our tests 
                echo  "on Hyper-V too, however in this instance it won't work. With Secure Boot enabled, Hyper-V can only"
                echo  run in either  UEFI Windows Mode or UEFI 3rd party mode. If you are seeing this message it means that 
                echo  "you are running in UEFI 3rd party mode, and won't be able to continue with Windows installation."
                echo
                echo  ${} ${} ACTION: Disable Secure Boot to install Windows from iPXE. Then Re-Enable. 
                echo
                echo We have already submitted feedback to MSFT to request support on Hyper-V.
                echo IF you would like to upvote, the title is on the Feedback Hub is: 
                echo ${} ${} ${} ${fgwhite}Hyper-V should support more than one Secure Boot Template${fgdefault}
                echo

                prompt Press any key to continue... ||
                return

            end if
        end if
    end if


    set bootwim ${deploymnetliveBlob}/${buildarch}/boot.wim
    if ( iseq ${buildarch} arm64 )
        set myhash <# (get-filehash "$TargetDir\winpe.arm64\boot.wim" | % hash).tolower() #>
    else
        set myhash <# (get-filehash "$TargetDir\winpe.amd64\boot.wim" | % hash).tolower() #>
    end if

    initrd -n winpeshl.ini  ${ipxeServer}/winpeshl.ini ||
    call LoadWinPE ${ipxeServer}/WinPE/${buildarch} ${bootwim} ${myhash}

end sub 

sub linuxlive

    call SetBackgroundPNG ""

    ## Future: Migrate to Bhodi,  smaller than Ubuntu ( 1GB to 3GB ). 

:ubuntu-22.04-KDE-squash
    # Size 2GB + 1GB  : Requires 8GB to load
    set squash_url https://github.com/netbootxyz/ubuntu-squash/releases/download/22.04.5-36909c4f/filesystem.squashfs
    set kernel_url https://github.com/netbootxyz/ubuntu-squash/releases/download/22.04.5-36909c4f/

    # BUGBUG https://github.com/DeploymentLive/iPXEOps/issues/3
    set cmdline ip=${ip}::${gateway}:${netmask}:myclient::off:${dns}

    call LoadLinux ${kernel_url} ${squash_url} ${ipxeServer}/shimx64.efi

    call SetBackgroundPNG Logo.png

end sub

#endregion

#region SubTools

sub main_tools

    while ( isset ${version}  )
        menu Advanced Tools Menu

        item --gap Other Tools and Installs

        #region OSD Cloud

        item osdcloud ${} ${} Advanced OSDCloud Install ${} ${} ${} ${} ${} ${} ${} ${} [WinPE With OSDCloud]

        #endregion

        item --gap

        #region netboot.xyz - ONLY if not running Secure Boot

        if ( iseq ${efi/SecureBoot} 01 )
            item --gap ${} ${} Linux Distros and Tools ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} [From Netboot.xyz] (Disabled for Secure Boot)
            item --gap ${} ${} DHCP Proxy Server ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} [for Deployment Live Cloud Ready Booting] (Turn off Secure Boot) 
        else
            item tools_xyz ${} ${} Linux Distros and Tools ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} [From Netboot.xyz]
            item tools_dhcpproxy ${} ${} DHCP Proxy Server ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} [for Deployment Live Cloud Ready Booting] 
        end if

        #endregion

        item --gap

        #region HP Tools - ONLY if HP Machine

        set isHP false
        iseq ${manufacturer} hp && set isHP true ||
        iseq ${manufacturer} Hewlett-Packard && set isHP true ||
        if ( iseq ${isHP} true )
            item tools_hp ${} ${} HP Recovery ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} [from hp.com]
        else
            item --gap ${} ${} HP Recovery ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} [from hp.com] (HP Only) 
        end if

        #endregion

        #region local PSD or MDT install - customer provides WIM file.

        if ( isset ${CustomerSuppliedWinPE} )
            item tools_localwinpe ${} ${} Local WinPE Installation ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} [From ${CustomerSuppliedWinPE}] 
        else
            item --gap  ${} ${} Local WinPE Installation ${} ${} ${} ${} ${} ${} ${} ${} ${} [set by CustomerSuppliedWinPE] (Placeholder)
        end if

        #endregion

        item --gap
        item --gap
        item --gap Local Tools  ${} ${} ${}  ${fgcyan}[${ipxeServer}]${fgdefault} ${catype}.<# (get-date).tostring('MM.dd.yy') #>
        item debug_diagnostics ${} ${} Show Network Status and Diagnostics
        item debug_config ${} ${} Show iPXE Config tool 
        item debug_shell ${} ${} Run iPXE Shell

        if ( NOT choose operation )
            break
        end if

        call SetBackgroundPNG ""
        call ${operation} 
        call SetBackgroundPNG Logo.png

    end while

end sub

sub tools_dhcpproxy

    set proxybase ${ipxeServer}/dhcpproxy
    imgfree ||
    kernel ${proxybase}/vmlinuz64 loglevel=3 initrd=initrd.magic ip=${ip} ||
    initrd ${proxybase}/tinycore.gz ||
    boot ||

    prompt Did not boot to DHCP Proxy, Note the error here. Press any key to continue...

end sub 

sub tools_localwinpe

    # Mostly un-tested, customer provides WIM file over http

    if ( NOT isset ${CustomerSuppliedWinPE_bootwim} )
        prompt ERROR: CustomerSuppliedWinPE_bootwim variable not set, cannot continue. Press any key to return to Tools Menu...
        return
    end if
    
    if ( NOT isset ${CustomerSuppliedWinPE_bootfiles} )
        prompt ERROR: CustomerSuppliedWinPE_bootfiles variable not set, cannot continue. Press any key to return to Tools Menu...
        return
    end if
    
    if ( NOT isset ${CustomerSuppliedWinPE_hash} )
        prompt ERROR: CustomerSuppliedWinPE_hash variable not set, cannot continue. Press any key to return to Tools Menu...
        return
    end if

    set i:int32 0
    while ( isset ${CustomerSuppliedWinPE_ExtraFiles${i}} )
        echo load ${CustomerSuppliedWinPE_ExtraFiles${i}}
        initrd ${CustomerSuppliedWinPE_ExtraFiles${i}}
        inc i ||
    wend
    
    call LoadWinPE ${CustomerSuppliedWinPE_bootfiles} ${CustomerSuppliedWinPE_bootwim} ${CustomerSuppliedWinPE_hash}

end sub 

sub tools_xyz
    echo start netboot.XYZ

    cpuid --ext 29 && set arch x86_64 || set arch i386
    iseq ${buildarch} arm64 && set arch arm64 ||
    set version 2.x
    set menu sig_check

    chain ${netbootxyz}/menu.ipxe
end sub

sub tools_hp

    echo "Start HP Recovery..."

    set HPHash  <# ((type "$TargetDir\recovery.mft" ) -match 'boot.wim').split(' ')[0] #>
    set HPBoot https://ftp.hp.com/pub/pcbios/CPR/sources/boot.wim

    call LoadWinPE ${ipxeServer}/WinPE/${buildarch} ${HPBoot} ${HPHash}


    chain HPRecovery.ipxe ||

end sub

#endregion

#region osdcloud

sub osdcloud

    # call SetBackgroundPNG Logo.png

    # OSDCloud Defaults
    set osdcloud_zti false
    set osdcloud_fw false
    set osdcloud_name Windows-%Rand:5%
    set osdcloud_final reboot
    set osdcloud_version 11
    set osdcloud_build 24H2
    iseq ${buildarch} arm64 && set osdcloud_arch Arm64 || set osdcloud_arch x64
    set osdcloud_edition Enterprise
    set osdcloud_activate Volume
    set osdcloud_language ${efi/PlatformLang:string}

    # set osdcloud_ppkg http://192.168.1.5/boot/DeploymentliveCorp.ppkg

    call SetBackgroundPNG ""

    set osd_adv_def osd_adv_zti
    while ( isset ${version} )

        menu OSDCloud Advanced Installation Options

        item --gap 
        item --gap 
        item --gap Operating System Version:
        item osd_adv_osver  ${} ${} ${} [ Windows ${osdcloud_version} ${osdcloud_build} ${osdcloud_arch} ${} ${} ${} ${} ]
        item osd_adv_oslang ${} ${} ${} [ ${osdcloud_language}  ${} ${} ${} ${} ]
        item osd_adv_oslic  ${} ${} ${} [ ${osdcloud_edition} ${osdcloud_activate} License ${} ${} ${} ${} ]

        item --gap 
        item --gap Options:
        if ( iseq ${osdcloud_zti} true )
            item osd_adv_zti ${} ${} ${} [#] ZTI Enabled  ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${}   (Fully Automated)
        else
            item osd_adv_zti ${} ${} ${} [ ] ZTI Enabled  ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${}   (Confirm Settings in WinPE)
        end if

        if ( iseq ${osdcloud_fw} true )
            item osd_adv_fw ${} ${} ${} [#] Update Firmware
        else
            item osd_adv_fw ${} ${} ${} [ ] Update Firmware
        end if

        item --gap ${} ${} ${} [ Disk0 ${} ${} ${} ${} ${} ${} ] ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${}   (Will Prompt if more than one disk )

        item --gap 
        item --gap Windows Imaging Designer Package URL (Optional)
        if ( isset ${osdcloud_ppkg} )
             item osd_adv_ppkg ${} ${} ${} [ ${osdcloud_ppkg}  ${} ${} ${} ]
        else
             item osd_adv_ppkg ${} ${} ${} [ ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${}  ${} ${} ${} ${} ${} ${} ${} ]
        end if

        item --gap 
        item --gap Final Action:
        if ( iseq ${osdcloud_final} none )
            item osd_adv_none ${} ${} ${} (#) None ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} (Stop at end of OSDCloud in WinPE)
            item osd_adv_reboot ${} ${} ${} ( ) Reboot
            item osd_adv_shutdown ${} ${} ${} ( ) Shutdown
        end if
        if ( iseq ${osdcloud_final} reboot )
            item osd_adv_none ${} ${} ${} ( ) None
            item osd_adv_reboot ${} ${} ${} (#) Reboot ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} (Reboot at end of WinPE into Windows)
            item osd_adv_shutdown ${} ${} ${} ( ) Shutdown
        end if
        if ( iseq ${osdcloud_final} shutdown )
            item osd_adv_none ${} ${} ${} ( ) None
            item osd_adv_reboot ${} ${} ${} ( ) Reboot
            item osd_adv_shutdown ${} ${} ${} (#) Shutdown  ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} ${} (Shutdown at end of WinPE)
        end if

        item --gap 
        item --gap 
        item --gap 

        item osd_adv_install ${fgyellow}Install now!${fgdefault}
        item --gap 
        item exit Exit

        choose --default ${osd_adv_def} osd_adv  || set osd_adv exit
        set osd_adv_def ${osd_adv}
        if ( iseq ${osd_adv} exit )

            call SetBackgroundPNG Logo.png
            return
        end if

        call ${osd_adv}

    end while

end sub

#region Advanced Dialog Handling

sub osd_adv_zti
    iseq ${osdcloud_zti} true && set osdcloud_zti false || set osdcloud_zti true
end sub

sub osd_adv_fw
    iseq ${osdcloud_fw} true && set osdcloud_fw false || set osdcloud_fw true
end sub

sub osd_adv_none
    set osdcloud_final none
end sub

sub osd_adv_reboot
    set osdcloud_final reboot
end sub

sub osd_adv_shutdown
    set osdcloud_final shutdown
end sub

sub osd_adv_osver

    menu Windows Version

    item win1124H2 Windows 11 24H2 x64
    item win1123H2 Windows 11 23H2 x64
    item win1122H2 Windows 11 22H2 x64
    item win1121H2 Windows 11 21H2 x64
    item win1022H2 Windows 10 22H2 x64

    choose --default win${osdcloud_version}${osdcloud_build} osver ||

    set osdcloud_version 11 ||
    iseq ${osver} win1022H2 && set osdcloud_version 10 || 

    set osdcloud_build 24H2 ||
    iseq ${osver} win1123H2 && set osdcloud_build 23H2 ||
    iseq ${osver} win1122H2 && set osdcloud_build 22H2 ||
    iseq ${osver} win1121H2 && set osdcloud_build 21H2 ||
    iseq ${osver} win1022H2 && set osdcloud_build 22H2 ||

end sub

sub osd_adv_oslic

    menu Windows Version

    item --gap
    item --gap Volume Licensing
    # item Home${sp}Volume Home (Volume)
    # item Home${sp}N${sp}Volume Home N (Volume)
    # item Home${sp}Single${sp}Language${sp}Volume Home Single Language (Volume)
    item Education${sp}Volume Education (Volume)
    item Education${sp}N${sp}Volume Education N (Volume)
    item Enterprise${sp}Volume Enterprise (Volume)
    item Enterprise${sp}N${sp}Volume Enterprise N (Volume)
    item Pro${sp}Volume Pro (Volume)
    item Pro${sp}N${sp}Volume Pro N (Volume)

    item --gap
    item --gap Retail Licensing 
    item Home${sp}Retail Home (Retail)
    item Home${sp}N${sp}Retail Home N (Retail)
    item Home${sp}Single${sp}Language${sp}Retail Home Single Language (Retail)
    item Education${sp}Retail Education (Retail)
    item Education${sp}N${sp}Retail Education N (Retail)
    #item Enterprise${sp}Retail Enterprise (Retail)
    #item Enterprise${sp}N${sp}Retail Enterprise N (Retail)
    item Pro${sp}Retail Pro (Retail)
    item Pro${sp}N${sp}Retail Pro N (Retail)

    if ( NOT choose --default ${osdcloud_edition}${sp}${osdcloud_activate} osdcloud_skuvol ) 
        return
    end if

    iseq ${osdcloud_skuvol} Home${sp}Volume && set osdcloud_edition Home ||
    iseq ${osdcloud_skuvol} Home${sp}N${sp}Volume && set osdcloud_edition Home${sp}N ||
    iseq ${osdcloud_skuvol} Home${sp}Single${sp}Language${sp}Volume && set osdcloud_edition Home${sp}Single${sp}Language ||
    iseq ${osdcloud_skuvol} Education${sp}Volume && set osdcloud_edition Education ||
    iseq ${osdcloud_skuvol} Education${sp}N${sp}Volume && set osdcloud_edition Education${sp}N ||
    iseq ${osdcloud_skuvol} Enterprise${sp}Volume && set osdcloud_edition Enterprise ||
    iseq ${osdcloud_skuvol} Enterprise${sp}N${sp}Volume && set osdcloud_edition Enterprise${sp}N ||
    iseq ${osdcloud_skuvol} Pro${sp}Volume && set osdcloud_edition Pro ||
    iseq ${osdcloud_skuvol} Pro${sp}N${sp}Volume && set osdcloud_edition Pro${sp}N ||

    iseq ${osdcloud_skuvol} Home${sp}Retail && set osdcloud_edition Home ||
    iseq ${osdcloud_skuvol} Home${sp}N${sp}Retail && set osdcloud_edition Home${sp}N ||
    iseq ${osdcloud_skuvol} Home${sp}Single${sp}Language${sp}Retail && set osdcloud_edition Home${sp}Single${sp}Language ||
    iseq ${osdcloud_skuvol} Education${sp}Retail && set osdcloud_edition Education ||
    iseq ${osdcloud_skuvol} Education${sp}N${sp}Retail && set osdcloud_edition Education${sp}N ||
    iseq ${osdcloud_skuvol} Enterprise${sp}Retail && set osdcloud_edition Enterprise ||
    iseq ${osdcloud_skuvol} Enterprise${sp}N${sp}Retail && set osdcloud_edition Enterprise${sp}N ||
    iseq ${osdcloud_skuvol} Pro${sp}Retail && set osdcloud_edition Pro ||
    iseq ${osdcloud_skuvol} Pro${sp}N${sp}Retail && set osdcloud_edition Pro${sp}N ||

    iseq ${osdcloud_skuvol} ${osdcloud_edition}${sp}Retail && set osdcloud_activate Retail || set osdcloud_activate Volume

end sub

sub osd_adv_oslang

    menu Windows Language and Locale options

    item ar-SA ar-SA - Arabic
    item bg-BG bg-BG - Bulgarian
    item cs-CZ cs-CZ - Czech
    item da-DK da-DK - Danish
    item de-DE de-DE - German
    item el-GR el-GR - Greek
    item en-GB en-GB - English (United Kingdom)
    item en-US en-US - English
    item es-ES es-ES - Spanish
    item es-MX es-MX - Spanish (Mexico)
    item et-EE et-EE - Estonian
    item fi-FI fi-FI - Finnish
    item fr-CA fr-CA - French (Canada)
    item fr-FR fr-FR - French
    item he-IL he-IL - Hebrew
    item hr-HR hr-HR - Croatian
    item hu-HU hu-HU - Hungarian
    item it-IT it-IT - Italian
    item ja-JP ja-JP - Japanese
    item ko-KR ko-KR - Korean
    item lt-LT lt-LT - Lithuanian
    item lv-LV lv-LV - Latvian
    item nb-NO nb-NO - Norwegian
    item nl-NL nl-NL - Dutch
    item pl-PL pl-PL - Polish
    item pt-BR pt-BR - Portuguese
    item pt-PT pt-PT - Portuguese (Portugal)
    item ro-RO ro-RO - Romanian
    item ru-RU ru-RU - Russian
    item sk-SK sk-SK - Slovak
    item sl-SI sl-SI - Slovenian
    item sr-Latn-RS sr-Latn-RS - Serbian
    item sv-SE sv-SE - Swedish
    item th-TH th-TH - Thai
    item tr-TR tr-TR - Turkish
    item uk-UA uk-UA - Ukrainian
    item zh-CN zh-CN - Chinese
    item zh-TW zh-TW - Chinese (Traditional)

    choose --default ${osdcloud_language} osdcloud_language || 

end sub

sub osd_adv_ppkg

    while ( isset ${version} )

        imgfre -n custom.ppkg ||

        form Install custom package from Image Configuration Designer
        item --gap
        item --gap
        item --gap  Note: Package must be available over the network.
        item osdcloud_ppkg Image Configuration Package [URL]:
        item --gap
        item --gap
        item username UserName (Optional)
        item -s password Password
        present

        if ( NOT isset ${osdcloud_ppkg} ) 
            break
        end if

        if ( isset ${username} && isset ${password} )
            echo Login with Credentials

            set encodedpw ${username}:${password}
            params
            param --header Authorization Basic ${encodedpw:base64}
        end if

        if ( initrd -n custom.ppkg ${osdcloud_ppkg}##params )
            break
        end if

        echo ERROR Downloading: ${osdcloud_ppkg}
        prompt Unable to download package. Please enter package URL Again

    wend

end sub

#endregion

sub osd_adv_install

    if ( iseq ${osdcloud_zti} true ) 
        set readtest wipe my disk
        call osd_zti_warning
        if ( NOT iseq ${candelete} ${readtest} )
            echo ${fgred}Aborting installation...${fgdefault}
            return
        end if
        initrd --name OSDCloud.zti.True.tag winpeshl.ini ||
    end if
    
    if ( iseq ${osdcloud_fw} true ) 
        initrd --name OSDCloud.firmware.true.tag winpeshl.ini ||
    end if

    if ( NOT iseq ${osdcloud_language} en-US ) 
        initrd --name OSDCloud.OSLanguage.${osdcloud_language}.tag winpeshl.ini ||
    end if

    if ( iseq ${osdcloud_final} reboot )
        initrd --name OSDCloud.Restart.true.tag winpeshl.ini ||
    end if

    if ( iseq ${osdcloud_final} shutdown )
        initrd --name OSDCloud.Shutdown.true.tag winpeshl.ini ||
    end if

    initrd --name OSDCloud.OSName.Windows ${osdcloud_version}${sp}${osdcloud_build}${sp}${osdcloud_arch}.tag winpeshl.ini ||
    initrd --name OSDCloud.OSEdition.${osdcloud_edition}.tag winpeshl.ini ||
    initrd --name OSDCloud.OSActivation.${osdcloud_activate}.tag winpeshl.ini ||

    echo ${cls}

    echo Begin installation
    echo
    echo Switches:
    echo "   ZTI:                 ${osdcloud_zti}"
    echo "   Update Firmware:     ${osdcloud_fw}"
    echo "   Final Action:        ${osdcloud_final}"

    echo
    echo OS Values
    echo "   OS Version:          Windows ${osdcloud_version} ${osdcloud_build}"
    echo "   Language:            ${osdcloud_language}"
    echo "   License:             ${osdcloud_edition}"

    echo Optional Pakage URL:
    echo "   URL:                ${osdcloud_ppkg}"
    echo 
    echo "Begin Boot!!!"

    imgstat

    echo 

    call osdboot

end sub

sub osd_zti_warning

    echo ${cls}
    echo
    echo
    echo
    echo
    echo ${} ${} ${} ${} ${} ${} ${fgred} WARNING: Fully automated installation of Windows is enabled! ${fgdefault}
    echo
    echo WARNING: Zero Touch Installation (ZTI) is enabled! ZTI will fully automate the 
    echo installation of Windows. You will not be able to change any settings from here on.
    echo 
    echo This installation of Windows is ${fgyellow}DESTRUCTIVE${fgdefault}, it will erase all data on the disk.
    echo After formatting the disk, there may be no way to recover data on the local disk.
    echo
    echo
    echo
    echo ${fggreen}Continue only if instructed by your IT Department.${fgdefault}
    echo
    echo
    echo
    echo please type in "${fggreen}${readtest}${fgdefault}" ( same case ) or Ctrl-C to cancel

    if (NOT read candelete)
        return
    end if
    echo ${fgred}Please type in "${fggreen}${readtest}${fgdefault}" ( same case ) or Ctrl-C to cancel ${fgdefault}
    while ( NOT iseq ${candelete} ${readtest} )
        if (NOT read candelete)
            return
        end if
    end while

end sub

#endregion

#region Generic Tools

sub LoadLinux
    # arg1 = path of vmlinuz and initrd files
    # arg2 = path of squashfs file ( Optional )
    # arg3 = path to shimx64.efi ( Optional )

    imgfree ||

    set kernel_url ${arg1}/
    isset ${arg2} && set squash_url ${arg2} || set squash_url ${arg1}/filesystem.squashfs

            echo kernel vmlinuz ip=dhcp boot=casper netboot=url url=${squash_url} initrd=initrd.magic netcfg/get_nameservers=8.8.8.8 ${cmdline}
    kernel ${kernel_url}vmlinuz ip=dhcp boot=casper netboot=url url=${squash_url} initrd=initrd.magic netcfg/get_nameservers=8.8.8.8 ${cmdline} ||
    initrd ${kernel_url}initrd ||
    isset ${arg3} && shim ${arg3} ||
    isset ${debug} && prompt --timeout 5000 Booting Linux LiveCD [5sec] ||
    boot ||

    prompt Did not boot to Linux Live CD, Note the error here. Press any key to continue...

end sub

sub LoadWinPE
    # arg1 = path of WinPE Files
    # arg2 = path of boot.wim file
    # arg3 = hash of boot.wim file otherwise "https"

    isset ${arg2} || set arg2 ${arg1}/boot.wim

    set WinPERoot ${arg1}
    iseq ${debug} true && set wimbootargs pause || set wimbootargs quiet

    kernel -n wimboot       ${WinPERoot}/wimboot  ${wimbootargs} ||
    initrd -n BCD           ${WinPERoot}/BCD          ||
    initrd -n boot.sdi      ${WinPERoot}/boot.sdi     ||
    initrd -n boot.wim      ${arg2}  ||

    if ( NOT iseq ${arg3} "https" )
        echo ${fgcyan}${arg3} ${fgdefault} Signature Check ...
        sha256sum boot.wim ||
        if ( NOT sha256sum -s ${arg3} boot.wim )
            echo Hashes for boot.wim not matching. Press ctrl-c to exit. 
            goto WinPEBootFail
        end if
    end if

    echo ${cls}
    imgstat ||
    boot ||

:WinPEBootFail
    prompt Did not boot to WinPE, Note the error here. Press any key to continue...

end sub

#endregion

#include common.sh
