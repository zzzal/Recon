# Recon
基于[0x9f99/Recon](https://github.com/0x9f99/Recon)修改的子域名挖掘/端口扫描工具。
## 使用说明
```
chmod +x ./Recon.sh
sudo ./Recon.sh domain
```
运行结束后会生成将结果保存到`Results/date/domain/`目录，其中 nmap 目录保存 nmap 的扫描结果，sub.txt 为子域名结果，c_ip.txt 为不含云服务器的 C 段 IP列表，url.txt 为 url 列表，result.xlsx 为最终结果。
## 其他
+ root 权限运行。
+ 不要在国内限制 Masscan 的机房使用，腾讯云/阿里云等。
+ 使用国内服务器可能会遇到网络问题。
