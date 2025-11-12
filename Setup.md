# My archlinux system setup on zero-book-13

## Handle power key
    - echo 'HandlePowerKey=ignore' >> /etc/systemd/logind.conf  
    - bash <(curl -s "https://end-4.github.io/dots-hyprland-wiki/setup.sh")
    - git clone https://github.com/1bharath-yadav/dotfiles.git ~/.dotfiles
    - cd ~/.dotfiles ;stow . ;sourcezsh
    - yay -S $(jq -r '.official[]?.name, .aur[]?.name' ~/.dotfiles/pkgs.json)

setup deamons in ~/.config/systemd/user look at ~/bin
setup torrc,proton-vpn 
setup .ssh and .env from cloud 
source apps



## place pied in local/bin folder

    - https://github.com/Elleo/pied
  

To link selective folders only,we first create directory and add other wanted nonlink folders and then stow.