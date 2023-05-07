# Inspired by: github.com/linuxserver/docker-openssh-server

FROM archlinux:latest

LABEL maintainer="Pagliacii"

RUN \
  echo "**** change the mirror ****" && \
  sed -i '1 i\Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist && \
  echo "**** upgrade pacman ****" && \
  systemd-machine-id-setup && \
  pacman-key --init && \
  pacman -Syyu --noconfirm && \
  pacman-db-upgrade && \
  echo "**** install sudo ****" && \
  pacman -S --noconfirm sudo && \
  echo "**** install openssh-server ****" && \
  pacman -S --noconfirm openssh && \
  echo "**** install neovim ****" && \
  pacman -S --noconfirm neovim git unzip && \
  echo "**** generate the host key ****" && \
  /usr/bin/ssh-keygen -A

COPY run.sh /run.sh
COPY nvim /config/nvim
WORKDIR /
EXPOSE 2222
ENTRYPOINT ["./run.sh", ">>", "/proc/1/fd/1"]

