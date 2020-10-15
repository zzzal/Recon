#!/bin/bash

TARGET="$1"

TIME=`date +"%Y%m%d%H%M"`
WORKING_DIR="$(cd "$(dirname "$0")" ; pwd -P)"
RESULTS_PATH="$WORKING_DIR/Results/$TIME/$1"
COMPONENTS_PATH="$WORKING_DIR/Components"

CLOUD_SERVER="腾讯云|阿里云|Amazon|Google|华为云|百度云|京东云|滴滴云|美团云|七牛云|Azure|DigitalOcean|Ucloud|IBM|金山云|西部数码"


RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;36m"
RESET="\033[0m"

setupEnvironments(){
    echo -e "${GREEN}[+] Setting things up.${RESET}"
    sudo apt update -y && apt install -y gcc g++ make libpcap-dev xsltproc snap curl python3-distutils

    if [ -x "$(command -v go)" ]; then
        echo -e "${BLUE}[-] Latest version of golang-go already installed. Skipping...${RESET}"
    else 
        echo -e "${GREEN}[+] Installing the latest version of Go...${RESET}"
        LATEST_GO=$(wget -qO- https://golang.org/dl/ | grep -oP 'go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1 | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2)
        wget https://dl.google.com/go/go$LATEST_GO.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go$LATEST_GO.linux-amd64.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
        sudo source /root/.profile
        rm -rf go$LATEST_GO*
    fi

    if [ -x "$(command -v python3)" ]; then
        if [[ "$(python3 -V | cut -d " " -f 2 | cut -d "." -f 1)" -eq 3 && "$(python3 -V | cut -d " " -f 2 | cut -d "." -f 2)" -gt 5 ]]; then
            echo -e "${BLUE}[-] Python3.6+ already installed. Skipping...${RESET}"
        else
            echo -e "${GREEN}[+] Installing Python3.8...${RESET}"
            sudo apt install python3.8-dev
        fi
    elif [ -x "$(command -v python)" ]; then
        if [[ "$(python -V | cut -d " " -f 2 | cut -d "." -f 1)" -eq 3 && "$(python -V | cut -d " " -f 2 | cut -d "." -f 2)" -gt 5 ]]; then
            echo -e "${BLUE}[-] Python3.6+ already installed. Skipping...${RESET}"
            echo -e "${GREEN}[+] Linking python to python3...${RESET}"
            # 创建软链接，统一为 python3
            sudo ln -s "$(which python)" "$(dirname $(which python))/python3"
        else
            echo -e "${GREEN}[+] Installing Python3.8...${RESET}"
            sudo apt install python3.8-dev
        fi
    fi

    if [ "$(python3 -m pip --version)" ]; then
        echo -e "${BLUE}[-] Pip for python3 already installed. Skipping...${RESET}"
    else
        echo -e "${GREEN}[+] Installing the latest version of Pip...${RESET}"
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py
        rm get-pip.py 
    fi
}

installTools(){
    LATEST_MASSCAN="1.0.6"
    if [ ! -x "$(command -v masscan)" ]; then
        echo -e "${GREEN}[+] Installing Masscan.${RESET}"
        git clone https://github.com/robertdavidgraham/masscan
        cd masscan
        make -j
        sudo make -j install
        cd $WORKING_DIR
        rm -rf masscan
    else
        if [ "$LATEST_MASSCAN" == "$(masscan -V | grep "Masscan version" | cut -d " " -f 3)" ]; then
            echo -e "${BLUE}[-] Latest version of Masscan already installed. Skipping...${RESET}"
        else
            echo -e "${GREEN}[+] Upgrading Masscan to the latest version.${RESET}"
            git clone https://github.com/robertdavidgraham/masscan
            cd masscan
            make -j
            sudo make -j install
            cd $WORKING_DIR
            rm -rf masscan*
        fi
    fi

    LATEST_NMAP="$(wget -qO- https://nmap.org/dist/ | grep -oP 'nmap-([0-9\.]+)\.tar\.bz2'| tail -n 1 | grep -oP 'nmap-[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2)"
    if [ ! -x "$(command -v nmap)" ]; then
        echo -e "${GREEN}[+] Installing Nmap.${RESET}"
        wget https://nmap.org/dist/nmap-$LATEST_NMAP.tar.bz2
        bzip2 -cd nmap-$LATEST_NMAP.tar.bz2 | tar xvf -
        cd nmap-$LATEST_NMAP
        ./configure
        make
        sudo make install
        cd $WORKING_DIR
        rm -rf nmap-$LATEST_NMAP*
    else 
        if [ "$LATEST_NMAP" == "$(nmap -V | grep "Nmap version" | cut -d " " -f 3)" ]; then
            echo -e "${BLUE}[-] Latest version of Nmap already installed. Skipping...${RESET}"
        else
            echo -e "${GREEN}[+] Upgrading Nmap to the latest version.${RESET}"
            wget https://nmap.org/dist/nmap-$LATEST_NMAP.tar.bz2
            bzip2 -cd nmap-$LATEST_NMAP.tar.bz2 | tar xvf -
            cd nmap-$LATEST_NMAP
            ./configure
            make -j
            sudo make -j install
            cd $WORKING_DIR
            rm -rf nmap-$LATEST_NMAP*
        fi 
    fi
    
    if [ -d "$COMPONENTS_PATH/nmap-parse-output" ];then
        echo -e "${BLUE}[-] Latest version of Nmap-parse-output already installed. Skipping...${RESET}"
    else
        echo -e "${GREEN}[+] Installing nmap-parse-output.${RESET}"
        cd $COMPONENTS_PATH && git clone https://github.com/zzzal/nmap-parse-output.git
        cd $WORKING_DIR
    fi
    
    if [ -e $COMPONENTS_PATH/nali ]; then
        echo -e "${BLUE}[-] Nali already installed. Skipping...${RESET}"
    else
        echo -e "${GREEN}[+] Installing Nali.${RESET}"
        go get -u -v github.com/zu1k/nali
        cp ~/go/bin/nali $COMPONENTS_PATH && $COMPONENTS_PATH/nali update
        rm -rf ~/go
    fi

}

installDNSTools(){
    if [ -e /snap/bin/amass ]; then
        echo -e "${BLUE}[-] Latest version of amass already installed. Skipping...${RESET}"
    else 
        snap install amass
    fi
    
    if [ -e /usr/bin/subfinder ]; then
        echo -e "${BLUE}[-] Latest version of Subfinder already installed. Skipping...${RESET}"
    else 
        wget https://github.com/projectdiscovery/subfinder/releases/download/v2.2.4/subfinder-linux-amd64.tar
	tar xf subfinder-linux-amd64.tar
        mv subfinder-linux-amd64 /usr/bin/subfinder
        rm -rf subfinder-linux-amd64.tar
    fi
}

EnumSubDomains(){
    echo -e "${GREEN}[+] Running Subfinder.${RESET}"
    /usr/bin/subfinder -d $1 -v -o dns.tmp > /dev/null
    echo -e "${GREEN}[+] Running Amass.${RESET}"
    /snap/bin/amass enum -d $1 -nolocaldb >> dns.tmp
    cat dns.tmp |sort|uniq > $RESULTS_PATH/sub.txt
    rm dns.tmp
}

domain2ip(){
    echo -e "${GREEN}[+] Extract IP Address.${RESET}"
    for i in `cat $RESULTS_PATH/sub.txt`; do
        cname_res=$(host -t CNAME $i)
        a_res=$(host -t A $i)
        if [[ $cname_res =~ "no CNAME record" ]]; then
            cdn="no CNAME"
            if [[ $a_res =~ "no A record" ]]; then
                continue
            fi
            ip=$(echo $a_res | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | cut -d " " -f1 | sed -n '1p')
            ip_location=$($COMPONENTS_PATH/nali $ip | cut -d "[" -f 2 | sed s'/.$//')
            if [[ -z $(echo $ip_location | grep -E -o $CLOUD_SERVER) ]]; then
                # 非云服务器，加入 c 段
                echo $(echo $ip | grep -E -o "([0-9]{1,3}[\.]){3}")0/24 >> c_ip_tmp.txt
            fi
            echo -e "${GREEN}[+] $i:IP=$ip, location=$ip_location ${RESET}"
            echo $i, $ip, $ip_location >> sub.tmp
        elif [[ $cname_res =~ "is an alias for" ]]; then
            cname=$(echo $cname_res | cut -d " " -f 6 | sed s'/.$//')
            cdn=$($COMPONENTS_PATH/nali cdn $cname | cut -d "[" -f 2 | sed s'/.$//')
            echo -e "${GREEN}[+] $i:CNAME=$cname, CDN/WAF=$cdn ${RESET}"
            echo $i, $cname, $cdn >> sub.tmp
        else
            continue
        fi
    done
    cat c_ip_tmp.txt | sort  | uniq -c | sort -rnk 1 | awk '{print $1, $2}' > c_ip.txt && rm c_ip_tmp.txt
}

portScan(){
    while read line; do
        subdomain=$(echo $line | cut -d ',' -f 1)
        ip=$(echo $line | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
        if [ $ip ]; then
            if [ ! -e $RESULTS_PATH/nmap/$ip.xml ]; then
                echo -e "${GREEN}[+] Scanning open port on $ip...${RESET}"

                echo -e "${GREEN}[+] Running Masscan.${RESET}"
                sudo masscan -p1-65535 --rate 3000 --wait=2 --open -oX $RESULTS_PATH/nmap/$ip.mas $ip
                open_ports=$(cat $RESULTS_PATH/nmap/$ip.mas | grep portid | cut -d "\"" -f 10 | sort -n | uniq | paste -sd,)

                echo -e "${GREEN}[+] Running Nmap.${RESET}"
                sudo nmap -sVC -p $open_ports --open -v -Pn -n -T4 -oX $RESULTS_PATH/nmap/$ip.xml $ip
            else
                open_ports=$(cat $RESULTS_PATH/nmap/$ip.mas | grep portid | cut -d "\"" -f 10 | sort -n | uniq | paste -sd,)
            fi
            # http、https 端口
            $COMPONENTS_PATH/nmap-parse-output/nmap-parse-output $RESULTS_PATH/nmap/$ip.xml http-ports | awk '{gsub(/'$ip'/,"'"$subdomain"'");print $1}' >> url.tmp
            $COMPONENTS_PATH/nmap-parse-output/nmap-parse-output $RESULTS_PATH/nmap/$ip.xml tls-ports | awk '{gsub(/'$ip'/,"'"$subdomain"'");print "https://"$1}' >> url.tmp
            res=""
            for p in ${open_ports//,/ }; do
                parse_result=$($COMPONENTS_PATH/nmap-parse-output/nmap-parse-output $RESULTS_PATH/nmap/$ip.xml port-info $p)
                service=$(echo $parse_result | cut -d ";" -f1); if [ ! $service ]; then service="Unknown"; fi
                component=$(echo $parse_result | cut -d ";" -f2); if [ ! $component ]; then component="Unknown"; fi
                component_version=$(echo $parse_result | cut -d ";" -f3); if [ ! $component_version ]; then component_version="Unknown"; fi
                res=$res$p":"$service";"$component";"$component_version","
            done
            if [ $res ]; then
                echo $line", "$res | sed s'/.$//'>> res.txt
            else
                echo $line", NULL" >> res.txt
            fi
        else
            echo $line", NULL" >> res.txt
        fi
    done < sub.tmp
    cat url.tmp | sort | uniq > url.txt && rm -rf url.tmp
    rm $RESULTS_PATH/nmap/*.mas
    rm sub.tmp
    python3 txt2xlsx.py
    mv result.xlsx $RESULTS_PATH
    mv url.txt $RESULTS_PATH
    rm res.txt
}

main(){
    if [[ $# -eq 0 ]]; then
        echo -e "\t${RED}[!] ERROR:${RESET} Invalid argument!\n"
        echo -e "\t${GREEN}[+] USAGE:${RESET}$0 domain.com\n"
        exit 1
    else
        if [ ! -e $COMPONENTS_PATH ]; then
            mkdir -p $COMPONENTS_PATH
            setupEnvironments
            installTools
            installDNSTools
        fi
        echo -e "${GREEN}[+] Creating results directory.${RESET}"
        mkdir -p $RESULTS_PATH
        mkdir -p $RESULTS_PATH/nmap
        EnumSubDomains $1
        domain2ip
        portScan
    fi
}

main $TARGET