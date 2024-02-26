FROM debian

# 设置中文环境
RUN apt-get update && apt-get install -y locales tzdata && rm -rf /var/lib/apt/lists/* \
    && localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias zh_CN.UTF-8
ENV LANG zh_CN.UTF-8 
ENV TZ=Asia/Shanghai

# 安装 XFCE 桌面、VNC 服务器和必要的依赖项
RUN apt-get update && apt-get install -y task-xfce-desktop \
    dbus-x11 \
    tigervnc-standalone-server \
    novnc python3-websockify wget git curl \
    && apt-get remove -y xfce4-power-manager && apt autoremove -y \
    # 修改本地缩放为novnc的默认设置和默认打开vnc.html
    && sed -i "s/UI.initSetting('resize', 'off');/UI.initSetting('resize', 'scale');/g" /usr/share/novnc/app/ui.js \
    && cp /usr/share/novnc/vnc.html /usr/share/novnc/index.html \
    && mkdir -p /root/tmp/img


# 设置默认壁纸（如果有）
# 复制图片文件到指定目录
COPY *.jpg /root/tmp/img/
COPY *.jpeg /root/tmp/img/
COPY *.png /root/tmp/img/
# 创建脚本
RUN echo '#!/bin/bash' >> /root/tmp/img/img.sh \
    && echo 'directory="/root/tmp/img"' >> /root/tmp/img/img.sh \
    && echo 'cd "$directory"' >> /root/tmp/img/img.sh \
    && wget https://alist.xct258.top/d/xct258/onedrive/%E5%85%B6%E5%AE%83/onedrive3/%E5%9B%BE%E7%89%87/%E7%BD%91%E7%AB%99%E8%83%8C%E6%99%AF%E5%9B%BE/pc/all/449.jpg \
    && echo 'image_files=$(find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))' >> /root/tmp/img/img.sh \
    && echo 'if [ -n "$image_files" ]; then' >> /root/tmp/img/img.sh \
    && echo '    mv $image_files /usr/share/images/desktop-base/default' >> /root/tmp/img/img.sh \
    && echo 'fi' >> /root/tmp/img/img.sh \
    && chmod +x /root/tmp/img/img.sh \
    && /root/tmp/img/img.sh \
    && rm -rf /root/tmp \
    # 启动脚本
    && echo '#!/bin/bash' >> /usr/local/bin/start.sh \
    && echo 'if [ ! -f "$HOME/.vnc/passwd" ]; then' >> /usr/local/bin/start.sh \
    && echo '    if [ -z "$VNC_PASSWORD" ]; then' >> /usr/local/bin/start.sh \
    && echo '        VNC_PASSWORD=$(openssl rand -base64 6)' >> /usr/local/bin/start.sh \
    && echo '        echo "没有设置VNC_PASSWORD环境变量，临时vnc密码为：$VNC_PASSWORD"' >> /usr/local/bin/start.sh \
    && echo '    fi' >> /usr/local/bin/start.sh \
    && echo 'mkdir -p ~/.vnc/' >> /usr/local/bin/start.sh \
    && echo 'echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd' >> /usr/local/bin/start.sh \
    && echo 'chmod 600 ~/.vnc/passwd' >> /usr/local/bin/start.sh \
    && echo 'fi' >> /usr/local/bin/start.sh \
    && echo 'tigervncserver -xstartup /usr/bin/xfce4-session -geometry 1920x1080 -localhost no :1 >/dev/null 2>&1' >> /usr/local/bin/start.sh \
    && echo 'websockify -D --web /usr/share/novnc 6901 localhost:5901 >/dev/null 2>&1' >> /usr/local/bin/start.sh \
    && echo 'tail -f /dev/null' >> /usr/local/bin/start.sh \
    && chmod +x /usr/local/bin/start.sh
ENTRYPOINT ["/usr/local/bin/start.sh"]
