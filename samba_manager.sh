#!/bin/bash

# Function to check if Samba is installed and install it if not
install_samba() {
    if ! dpkg -l | grep -q samba; then
        echo "Samba is not installed. Installing Samba..."
        sudo apt update && sudo apt install -y samba
        if [ $? -ne 0 ]; then
            echo "Failed to install Samba. Exiting."
            exit 1
        fi
    else
        echo "Samba is already installed."
    fi
}

# Function to display the menu
show_menu() {
    echo "1. Add Shared Folder"
    echo "2. Stop Sharing Folder"
    echo "3. Add User"
    echo "4. Delete User"
    echo "5. Restart Samba Service"
    echo "6. Stop Samba Service"
    echo "7. Exit"
}

# Function to add a shared folder
add_shared_folder() {
    read -p "Enter the path of the folder to be shared: " folder_path
    if [ ! -d "$folder_path" ]; then
        echo "The folder does not exist. Please create the folder first."
        return
    fi

    echo "Available users:"
    awk -F':' '{ print $1 }' /etc/passwd

    read -p "Enter the valid username for the shared folder: " valid_user
    if ! id -u "$valid_user" >/dev/null 2>&1; then
        echo "User does not exist."
        return
    fi

    sudo bash -c "cat >> /etc/samba/smb.conf <<EOL
[$(basename "$folder_path")]
   path = $folder_path
   browsable = yes
   read only = no
   valid users = $valid_user
EOL"

    sudo systemctl restart smbd
    echo "Shared folder added and Samba restarted."
}

# Function to stop sharing a folder
stop_sharing_folder() {
    read -p "Enter the name of the share to stop: " share_name
    sudo sed -i "/^\[$share_name\]/,/^$/ s/^/#/" /etc/samba/smb.conf
    sudo systemctl restart smbd
    echo "Sharing stopped for $share_name and Samba restarted."
}

# Function to add a Samba user
add_user() {
    read -p "Enter the username to add: " username
    sudo useradd -m "$username"
    sudo smbpasswd -a "$username"
    echo "User $username added to the system and Samba."
}

# Function to delete a Samba user
delete_user() {
    echo "Available users:"
    awk -F':' '{ print $1 }' /etc/passwd

    read -p "Enter the username to delete: " username
    if ! id -u "$username" >/dev/null 2>&1; then
        echo "User does not exist."
        return
    fi

    sudo smbpasswd -x "$username"
    sudo userdel -r "$username"
    echo "User $username deleted from the system and Samba."
}

# Function to restart the Samba service
restart_samba() {
    sudo systemctl restart smbd
    echo "Samba service restarted."
}

# Function to stop the Samba service
stop_samba() {
    sudo systemctl stop smbd
    echo "Samba service stopped."
}

# Main script logic
install_samba

while true; do
    show_menu
    read -p "Select an option: " option
    case $option in
        1)
            add_shared_folder
            ;;
        2)
            stop_sharing_folder
            ;;
        3)
            add_user
            ;;
        4)
            delete_user
            ;;
        5)
            restart_samba
            ;;
        6)
            stop_samba
            ;;
        7)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select again."
            ;;
    esac
done
