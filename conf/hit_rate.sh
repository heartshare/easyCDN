#!/bin/bash
# proxy_cache hit rate

Time=`date "+%Y-%m-%d %H:%M:%S"`
if [ $1x != x ]; then
    if [ -e $1 ]; then
        HIT=`cat $1 | grep HIT | wc -l`
        ALL=`cat $1 | wc -l`
        Hit_rate=`echo "scale=2;($HIT/$ALL)*100" | bc`
        cat >/usr/local/nginx/html/hit.html<<-EOF
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Hit Rate</title>
</head>
<body>
    <table>
        <p>Online Hit Rate View Below:</p>
        <tr>
            <td>All:</td>
            <td>$ALL</td>
        </tr>
        <tr>
            <td>Hit:</td>
            <td>$HIT</td>
        </tr>
        <tr>
            <td>Hit Rate:</td>
            <td>$Hit_rate%</td>
        </tr>
        <tr>
            <td>Last Update:</td>
            <td>$Time</td>
        </tr>
    </table>
    <hr>
    <cite>Powered by <a href="https://github.com/xiaosong/easyCDN">easyCDN</a></cite>
</body>
</html>
EOF
        echo "All: $ALL"
        echo "Hit: $HIT"
        echo "Hit Rate: $Hit_rate%"
        echo "Last Update: $Time"
    else
        echo "$1 not exsist!"
    fi
else
    echo "usage: ./hit_rate.sh file_path"
fi