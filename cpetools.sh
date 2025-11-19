#!/bin/bash
# 模拟cpetools.sh脚本用于测试

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -t0)
            shift
            COMMAND="$1"
            shift
            ;;
        *)
            COMMAND="$1"
            shift
            ;;
    esac
done

# 模拟AT命令响应
case "$COMMAND" in
    "AT")
        echo "OK"
        ;;
    "AT+CGMI")
        echo "Quectel"
        echo "OK"
        ;;
    "AT+CGMM")
        echo "EC20"
        echo "OK"
        ;;
    "AT+CGMR")
        echo "EC20CEHHLGR08A04M1G"
        echo "OK"
        ;;
    "AT+CSQ")
        echo "+CSQ: 20,99"
        echo "OK"
        ;;
    "AT+CREG?")
        echo "+CREG: 0,1"
        echo "OK"
        ;;
    "AT+COPS?")
        echo "+COPS: 0,0\"CHINA MOBILE\",7"
        echo "OK"
        ;;
    "AT+CPIN?")
        echo "+CPIN: READY"
        echo "OK"
        ;;
    "AT+CGREG=2")
        echo "OK"
        ;;
    "AT+CGREG?")
        echo "+CGREG: 0,1"
        echo "OK"
        ;;
    "AT^MONSC")
        echo "^MONSC: 1,460,00,1,1,157,1,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157,157"
        echo "OK"
        ;;
    "AT^HFREQINFO?")
        echo "^HFREQINFO: 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
        echo "OK"
        ;;
    "AT^HCSQ?")
        echo "^HCSQ: \"LTE\",20,99,157,24"
        echo "OK"
        ;;
    "AT^EONS=2")
        echo "^EONS: 2,46000,\"CHN-UNICOM\",\"UNICOM\",0,7,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
        echo "OK"
        ;;
    "AT^DSAMBR=1")
        echo "^DSAMBR: 1,0,0,0"
        echo "OK"
        ;;
    "AT^DSAMBR=8")
        echo "^DSAMBR: 8,0,0,0"
        echo "OK"
        ;;
    "AT+CGEQOSRDP=8")
        echo "+CGEQOSRDP: 8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
        echo "OK"
        ;;
    "AT+CGEQOSRDP=1")
        echo "+CGEQOSRDP: 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
        echo "OK"
        ;;
    *)
        echo "ERROR: Unknown command"
        exit 1
        ;;
esac