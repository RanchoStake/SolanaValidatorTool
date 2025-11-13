#!/bin/bash

# Rancho Stake's Solana Validator Tool - Setup Script
# This script sets up the Agave or Jito validator clients for Solana

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Global variables
SELECTED_CLIENT=""
SELECTED_CLUSTER=""
TOTAL_STEPS=9

# Function to clear screen and show header
show_header() {
    clear
    echo -e "${RED}"
    cat << 'EOF'
####################################################
######################+=+=++*##*++*#################
####################*---++**+=------################
###################*----------------+###############
###################------------------###############
#############*+=*#*++++==-----------=*##############
##########*==*#*++=====+*##+=----=*#*+++*###########
#########=+#*=-------------=+****+=-------+#########
########+#*=--------------------------------=#######
########*-------------------------------------######
#######======================================*######
###################****######*********##############
###################=---+#####*--------*#############
###############+-##------------------=*#############
###############==##-----------------##++++##########
###############-=#*-----------------+==*--##########
###############-+#+-----=-------------+#=-##########
###############+##***###=-----------==-=--##########
#########################+----------+###############
###############=+##########+-----------#############
###############=--=++++++++=----------+#############
##################=-----------------=*##############
#################+----------------=*################
####################################################
EOF
    echo -e "${NC}"
    echo -e "${BOLD}${RED}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║   Rancho Stake's Solana Validator Tool - Setup   ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Function to show progress indicator
show_progress() {
    local current_step=$1
    local total_steps=$2
    echo -e "${MAGENTA}Progress: [$current_step of $total_steps]${NC}"
    echo ""
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to pause and wait for user
pause() {
    echo ""
    read -p "Press [Enter] to continue..."
}

# Function to display status box
display_status() {
    local label="$1"
    local status="$2"
    
    if [ "$status" = "INSTALLED" ]; then
        echo -e "  ${BOLD}$label:${NC} ${GREEN}✅ $status${NC}"
    else
        echo -e "  ${BOLD}$label:${NC} ${RED}❌ $status${NC}"
    fi
}

# Function to display extended status with version
display_status_extended() {
    local label="$1"
    local status="$2"
    local version="$3"
    
    if [ "$status" = "INSTALLED" ]; then
        if [ -n "$version" ]; then
            echo -e "  ${BOLD}$label:${NC} ${GREEN}✅ $status${NC} ${CYAN}($version)${NC}"
        else
            echo -e "  ${BOLD}$label:${NC} ${GREEN}✅ $status${NC}"
        fi
    else
        echo -e "  ${BOLD}$label:${NC} ${RED}❌ $status${NC}"
    fi
}

# Help screen
help_screen() {
    show_header
    echo -e "${BOLD}${CYAN}HELP INFORMATION${NC}"
    echo -e "${YELLOW}===================================================${NC}"
    echo ""
    echo "This setup wizard will guide you through:"
    echo "  - Checking system requirements"
    echo "  - Installing dependencies"
    echo "  - Building Solana validator software"
    echo "  - Configuring system settings"
    echo "  - Creating systemd services"
    echo ""
    echo "Total estimated time: 30-45 minutes"
    echo ""
    echo "This is a free, open-source tool developed by Rancho Stake 🤠🥩 and community contributors"
    echo ""
    echo "https://ranchostake.xyz | https://github.com/RanchoStake/SolanaValidatorTool"
    echo ""
    pause
}

# Welcome screen (Step 0)
welcome_screen() {
    show_header
    
    echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}           📋 Installation Status Check${NC}"
    echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    
    # Check for solana CLI with version
    if command_exists solana; then
        local solana_version=$(solana --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        display_status_extended "Solana CLI" "INSTALLED" "$solana_version"
    else
        display_status "Solana CLI" "NOT INSTALLED"
    fi
    
    # Check for agave-validator with version
    if command_exists agave-validator; then
        local agave_version=$(agave-validator --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        display_status_extended "Agave Validator" "INSTALLED" "$agave_version"
    else
        display_status "Agave Validator" "NOT INSTALLED"
    fi
    
    # Check validator catchup status if validator is installed
    if command_exists solana; then
        echo ""
        echo -e "${CYAN}Checking validator catchup status...${NC}"
        local catchup_output=$(timeout 5 solana catchup --our-localhost 2>&1 || echo "error")
        
        if echo "$catchup_output" | grep -q "has caught up"; then
            echo -e "  ${BOLD}Catchup Status:${NC} ${GREEN}✅ Caught up${NC}"
        elif echo "$catchup_output" | grep -q "catching up"; then
            local slot_info=$(echo "$catchup_output" | grep -oP '\d+ slots behind' || echo "in progress")
            echo -e "  ${BOLD}Catchup Status:${NC} ${YELLOW}⚠️  Catching up ($slot_info)${NC}"
        elif echo "$catchup_output" | grep -q "error" || echo "$catchup_output" | grep -q "Connection refused" || echo "$catchup_output" | grep -q "failed"; then
            echo -e "  ${BOLD}Catchup Status:${NC} ${RED}❌ Error or validator not running${NC}"
        else
            echo -e "  ${BOLD}Catchup Status:${NC} ${YELLOW}⚠️  Unable to determine${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Select an option:${NC}"
    echo -e "  ${GREEN}1)${NC} SIMPLE INSTALL - Complete installation (all steps)"
    echo -e "  ${GREEN}2)${NC} ADVANCED INSTALL - Select specific steps"
    echo -e "  ${GREEN}3)${NC} UPDATE - Update validator client"
    echo -e "  ${BLUE}4)${NC} HELP - Show help information"
    echo -e "  ${RED}5)${NC} EXIT - Quit installer"
    echo ""
    
    read -p "Enter your choice [1-5]: " choice
    
    case $choice in
        1)
            return 0
            ;;
        2)
            advanced_install_menu
            ;;
        3)
            update_mode
            ;;
        4)
            help_screen
            welcome_screen
            ;;
        5)
            quit_tool
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${NC}"
            sleep 2
            welcome_screen
            ;;
    esac
}

# Advanced Install Menu
advanced_install_menu() {
    while true; do
        show_header
        echo -e "${BOLD}${CYAN}ADVANCED INSTALL MENU${NC}"
        echo -e "${YELLOW}===================================================${NC}"
        echo ""
        echo "Select a specific step to run:"
        echo ""
        echo -e "  ${GREEN}1)${NC} Step 1: Disk Check"
        echo -e "  ${GREEN}2)${NC} Step 2: Directory Check"
        echo -e "  ${GREEN}3)${NC} Step 3: Dependencies Check"
        echo -e "  ${GREEN}4)${NC} Step 4: Download and Build Solana CLI"
        echo -e "  ${GREEN}5)${NC} Step 5: Apply PATH and Symlink"
        echo -e "  ${GREEN}6)${NC} Step 6: Cluster Set"
        echo -e "  ${GREEN}7)${NC} Step 7: Create Validator Script"
        echo -e "  ${GREEN}8)${NC} Step 8: Create System Service"
        echo -e "  ${GREEN}9)${NC} Step 9: Linux System Tuning"
        echo -e "  ${BLUE}0)${NC} Return to Main Menu"
        echo ""
        
        read -p "Enter your choice [0-9]: " step_choice
        
        case $step_choice in
            1)
                disk_check 1
                ;;
            2)
                directory_check 2
                ;;
            3)
                dependencies_check 3
                ;;
            4)
                download_and_build 4
                ;;
            5)
                apply_path_and_symlink 5
                ;;
            6)
                cluster_set 6
                ;;
            7)
                create_script 7
                ;;
            8)
                create_system_service 8
                ;;
            9)
                linux_system_tuning 9
                ;;
            0)
                welcome_screen
                return
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Update Mode
update_mode() {
    show_header
    echo -e "${BOLD}${CYAN}UPDATE MODE${NC}"
    echo -e "${YELLOW}===================================================${NC}"
    echo ""
    echo "This will update your Agave or Jito validator client by:"
    echo "  1. Downloading and building a new version"
    echo "  2. Updating the symlink to the new version"
    echo "  3. Performing a daemon-reload and restart of the system service"
    echo ""
    echo -e "${YELLOW}Note: This will not stop your currently running validator.${NC}"
    echo -e "${YELLOW}      You'll need to manually restart it when ready.${NC}"
    echo ""
    
    read -p "Continue with update? [Y/N]: " continue_update
    
    if [[ "$continue_update" =~ ^[Nn]$ ]]; then
        echo -e "${CYAN}Update cancelled.${NC}"
        sleep 2
        welcome_screen
        return
    fi
    
    # Step 4: Download and Build
    download_and_build 1 2
    
    # Step 5: Apply PATH and Symlink
    apply_path_and_symlink 2 2
    
    # Offer to reload and restart service
    show_header
    echo -e "${BOLD}${CYAN}✅ UPDATE COMPLETE${NC}"
    echo -e "${YELLOW}===================================================${NC}"
    echo ""
    echo "The new validator version has been built and symlinked."
    echo ""
    echo "To apply the update, you need to reload systemd and restart"
    echo "the validator service. This will cause downtime."
    echo ""
    echo -e "${YELLOW}⚠️ WARNING: This will restart your validator!${NC}"
    echo ""
    
    read -p "Reload systemd and restart validator service now? [Y/N]: " restart_choice
    
    if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${CYAN}Reloading systemd daemon...${NC}"
        sudo systemctl daemon-reload
        echo -e "  ${GREEN}✅ Systemd daemon reloaded${NC}"
        
        echo ""
        echo -e "${CYAN}Restarting validator service...${NC}"
        sudo systemctl restart sol.service
        echo -e "  ${GREEN}✅ Validator service restarted${NC}"
        
        echo ""
        echo -e "${BOLD}${GREEN}✅ Update applied successfully!${NC}"
    else
        echo ""
        echo -e "${CYAN}Skipping service restart.${NC}"
        echo ""
        echo "When you're ready to apply the update, run:"
        echo -e "  ${BLUE}sudo systemctl daemon-reload && sudo systemctl restart sol.service${NC}"
    fi
    
    echo ""
    pause
    welcome_screen
}

# Step 1: Disk Check
disk_check() {
    local step_num=${1:-1}
    show_header
    show_progress "$step_num" "$TOTAL_STEPS"
    echo -e "${BOLD}${CYAN}🔍 STEP 1: DISK CHECK${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "Solana clients need two fast disks (NVMe) in the 'ext4' or 'xfs'"
    echo "formats for its 'ledger' and 'account' databases. This step will"
    echo "perform a check to see if you have these properly configured in"
    echo "your system."
    echo ""
    pause
    
    local checks_passed=true
    local fail_messages=()
    
    # Check a: At least two storage devices in ext4 or xfs format
    echo -e "${CYAN}Checking for ext4/xfs formatted drives...${NC}"
    local drive_count=$(lsblk -f | grep -E "ext4|xfs" | grep -v "^$(df / | tail -1 | awk '{print $1}' | sed 's|/dev/||')" | wc -l)
    
    if [ "$drive_count" -lt 2 ]; then
        checks_passed=false
        fail_messages+=("⚠️ Less than 2 ext4/xfs drives found (excluding OS drive)")
    else
        echo -e "  ${GREEN}✅ Found $drive_count ext4/xfs formatted drives${NC}"
    fi
    
    # Check b: UUID's in fstab
    echo -e "${CYAN}Checking fstab for drive UUIDs...${NC}"
    if ! grep -q "UUID=" /etc/fstab 2>/dev/null; then
        checks_passed=false
        fail_messages+=("⚠️ No UUID entries found in /etc/fstab")
    else
        echo -e "  ${GREEN}✅ UUID entries found in fstab${NC}"
    fi
    
    # Check c: Mount points in /mnt/ledger and /mnt/accounts
    echo -e "${CYAN}Checking for /mnt/ledger and /mnt/accounts mount points...${NC}"
    local ledger_found=false
    local accounts_found=false
    
    if grep -q "/mnt/ledger" /etc/fstab 2>/dev/null; then
        ledger_found=true
        echo -e "  ${GREEN}✅ /mnt/ledger found in fstab${NC}"
    else
        checks_passed=false
        fail_messages+=("⚠️ /mnt/ledger not found in fstab")
    fi
    
    if grep -q "/mnt/accounts" /etc/fstab 2>/dev/null; then
        accounts_found=true
        echo -e "  ${GREEN}✅ /mnt/accounts found in fstab${NC}"
    else
        checks_passed=false
        fail_messages+=("⚠️ /mnt/accounts not found in fstab")
    fi
    
    # Check d: R/W permissions
    echo -e "${CYAN}Checking read/write permissions...${NC}"
    if [ -d "/mnt/ledger" ] && [ -w "/mnt/ledger" ] && [ -r "/mnt/ledger" ]; then
        echo -e "  ${GREEN}✅ /mnt/ledger has proper r/w permissions${NC}"
    else
        if [ -d "/mnt/ledger" ]; then
            checks_passed=false
            fail_messages+=("⚠️ /mnt/ledger exists but lacks proper r/w permissions")
        fi
    fi
    
    if [ -d "/mnt/accounts" ] && [ -w "/mnt/accounts" ] && [ -r "/mnt/accounts" ]; then
        echo -e "  ${GREEN}✅ /mnt/accounts has proper r/w permissions${NC}"
    else
        if [ -d "/mnt/accounts" ]; then
            checks_passed=false
            fail_messages+=("⚠️ /mnt/accounts exists but lacks proper r/w permissions")
        fi
    fi
    
    echo ""
    
    if [ "$checks_passed" = true ]; then
        echo -e "${BOLD}${GREEN} All Disk Checks passed! ✅${NC}"
        pause
        return 0
    else
        echo -e "${BOLD}${RED} Disk checks failed! ⚠️${NC}"
        echo ""
        echo "Issues found:"
        for msg in "${fail_messages[@]}"; do
            echo "  $msg"
        done
        echo ""
        echo "Please verify that your disks are properly set up, then run this"
        echo "install script again!"
        echo ""
        pause
        exit 1
    fi
}

# Step 2: Directory Check
directory_check() {
    local step_num=${1:-2}
    show_header
    show_progress "$step_num" "$TOTAL_STEPS"
    echo -e "${BOLD}${CYAN}📁 STEP 2: DIRECTORY CHECK${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "Checking for required directories in your home folder..."
    echo ""
    
    local dirs_to_check=(
        "$HOME/agave-current"
        "$HOME/src"
        "$HOME/bin"
    )
    
    local dirs_to_create=()
    
    for dir in "${dirs_to_check[@]}"; do
        if [ -d "$dir" ]; then
            if [ -r "$dir" ] && [ -w "$dir" ]; then
                echo -e "  ${GREEN}✅ $dir exists with proper permissions${NC}"
            else
                echo -e "  ${YELLOW}⚠️ $dir exists but needs permission fix${NC}"
                chmod u+rw "$dir"
                echo -e "    ${GREEN}✅ Permissions fixed${NC}"
            fi
        else
            echo -e "  ${YELLOW}⚠️ $dir does not exist${NC}"
            dirs_to_create+=("$dir")
        fi
    done
    
    if [ ${#dirs_to_create[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}The install wizard will create directories in your home address${NC}"
        echo -e "${YELLOW}that the Validator Tool will need later on.${NC}"
        echo ""
        read -p "Proceed with directory creation? [Y/N]: " proceed
        
        if [[ ! "$proceed" =~ ^[Nn]$ ]]; then
            for dir in "${dirs_to_create[@]}"; do
                mkdir -p "$dir"
                chmod u+rw "$dir"
                echo -e "  ${GREEN}✅ Created $dir${NC}"
            done
        else
            echo -e "${RED}Setup cannot continue without required directories.${NC}"
            exit 1
        fi
    fi
    
    echo ""
    echo -e "${BOLD}${GREEN} 🗂️ Directory check complete! ✅${NC}"
    pause
}

# Step 3: Dependencies Check
dependencies_check() {
    local step_num=${1:-3}
    show_header
    show_progress "$step_num" "$TOTAL_STEPS"
    echo -e "${BOLD}${CYAN}📦 STEP 3: DEPENDENCIES CHECK${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${MAGENTA} ⏱ Estimated time: 3-5 minutes${NC}"
    echo ""
    
    # Check for Rust
    echo -e "${CYAN}Checking for Rust...${NC}"
    if [ -f "$HOME/.cargo/bin/rustc" ]; then
        echo -e "  ${GREEN}✅ Rust is installed${NC}"
    else
        echo -e "  ${YELLOW}⚠️ Rust is not installed${NC}"
        echo ""
        echo "Rust is required for building the Solana CLI."
        read -p "Install Rust now? [Y/N]: " install_rust
        
        if [[ ! "$install_rust" =~ ^[Nn]$ ]]; then
            echo ""
            echo "Installing Rust..."
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
            
            # Source cargo environment
            source "$HOME/.cargo/env"
            
            # Add to PATH for current session
            export PATH="$HOME/.cargo/bin:$PATH"
            
            echo -e "${GREEN}✅ Rust installed successfully${NC}"
        else
            echo -e "${RED}Setup cannot continue without Rust.${NC}"
            exit 1
        fi
    fi
    
    # Ensure cargo is in PATH
    if ! command_exists cargo; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    
    echo ""
    
    # Check for Anchor
    echo -e "${CYAN}Checking for Anchor...${NC}"
    if command_exists anchor; then
        echo -e "  ${GREEN}✅ Anchor is installed${NC}"
    else
        echo -e "  ${YELLOW}⚠️ Anchor is not installed${NC}"
        echo ""
        echo "Anchor is required for Solana program development."
        read -p "Install Anchor now? [Y/N]: " install_anchor
        
        if [[ ! "$install_anchor" =~ ^[Nn]$ ]]; then
            echo ""
            echo "Installing Anchor (this may take a while)..."
            cargo install --git https://github.com/coral-xyz/anchor anchor-cli
            
            echo -e "${GREEN}✅ Anchor installed successfully${NC}"
        else
            echo -e "${YELLOW}Note: You may need Anchor for certain validator operations${NC}"
        fi
    fi
    
    echo ""
    
    # Check for system dependencies
    echo -e "${CYAN}Checking for system dependencies...${NC}"
    
    local dependencies=(
        "build-essential"
        "pkg-config"
        "libudev-dev"
        "libssl-dev"
        "llvm"
        "libclang-dev"
        "protobuf-compiler"
    )
    
    local missing_deps=()
    
    for dep in "${dependencies[@]}"; do
        if dpkg -l | grep -q "^ii  $dep"; then
            echo -e "  ${GREEN}✅ $dep is installed${NC}"
        else
            echo -e "  ${YELLOW}⚠️ $dep is missing${NC}"
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        echo "Missing dependencies: ${missing_deps[*]}"
        echo ""
        read -p "Install missing dependencies now? [Y/n]: " install_deps
        
        if [[ ! "$install_deps" =~ ^[Nn]$ ]]; then
            echo ""
            echo "Installing dependencies (requires sudo)..."
            sudo apt-get update
            sudo apt-get install -y "${missing_deps[@]}"
            echo -e "${GREEN}✅ Dependencies installed successfully${NC}"
        else
            echo -e "${RED}Setup cannot continue without required dependencies.${NC}"
            exit 1
        fi
    fi
    
    echo ""
    echo -e "${BOLD}${GREEN} ✅ All dependencies satisfied! 📦${NC}"
    pause
}

# Step 4: Download and Build Solana CLI
download_and_build() {
    local step_num=${1:-4}
    local total_steps=${2:-$TOTAL_STEPS}
    show_header
    show_progress "$step_num" "$total_steps"
    echo -e "${BOLD}${CYAN}⬇️  STEP 4: DOWNLOAD AND BUILD SOLANA CLI${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${MAGENTA} ⏱ Estimated time: 8-10 minutes${NC}"
    echo ""
    echo "Select which client to install:"
    echo ""
    echo -e "  ${GREEN}1)${NC} Agave (Official Solana client)"
    echo -e "  ${GREEN}2)${NC} Jito (MEV-optimized client)"
    echo ""
    
    read -p "Enter your choice [1-2]: " client_choice
    
    local repo_url=""
    local client_name=""
    
    case $client_choice in
        1)
            repo_url="https://github.com/anza-xyz/agave.git"
            client_name="agave"
            SELECTED_CLIENT="agave"
            ;;
        2)
            repo_url="https://github.com/jito-foundation/jito-solana.git"
            client_name="jito"
            SELECTED_CLIENT="jito"
            ;;
        *)
            echo -e "${RED}Invalid choice.${NC}"
            sleep 2
            download_and_build "$step_num" "$total_steps"
            return
            ;;
    esac
    
    echo ""
    echo -e "${BOLD}Enter the version tag you want to install:${NC}"
    echo ""
    
    if [ "$client_choice" = "1" ]; then
        echo -e "${CYAN}Format for Agave:${NC} ${YELLOW}vX.Y.Z${NC}"
        echo -e "${CYAN}Example:${NC} v3.0.10"
    else
        echo -e "${CYAN}Format for Jito:${NC} ${YELLOW}vX.Y.Z-jito${NC}"
        echo -e "${CYAN}Example:${NC} v3.0.10-jito"
    fi
    
    echo ""
    echo -e "${YELLOW}Tip: Check the releases page on GitHub for available versions${NC}"
    echo ""
    
    read -p "Enter version tag: " version_tag
    
    # Validate version tag format
    if [ -z "$version_tag" ]; then
        echo -e "${RED}Error: Version tag cannot be empty${NC}"
        sleep 2
        download_and_build "$step_num" "$total_steps"
        return
    fi
    
    echo ""
    echo -e "${CYAN}Downloading $client_name version $version_tag...${NC}"
    
    cd "$HOME/src"
    
    # Create versioned directory name
    local versioned_name="${client_name}-${version_tag}"
    
    # Check if version already exists
    if [ -d "$HOME/src/$versioned_name" ]; then
        echo -e "${YELLOW}⚠️ Version $versioned_name already exists!${NC}"
        echo ""
        read -p "Skip building and use existing version? [Y/N]: " use_existing
        
        if [[ ! "$use_existing" =~ ^[Nn]$ ]]; then
            SELECTED_CLIENT="$versioned_name"
            echo -e "${GREEN}✅ Using existing $versioned_name${NC}"
            pause
            return
        else
            echo -e "${YELLOW}Removing old version and rebuilding...${NC}"
            rm -rf "$HOME/src/$versioned_name"
        fi
    fi
    
    # Clone to temporary directory first
    local temp_dir="${client_name}-temp"
    if [ -d "$HOME/src/$temp_dir" ]; then
        rm -rf "$HOME/src/$temp_dir"
    fi
    
    git clone "$repo_url" "$temp_dir"
    
    # Checkout the specified version tag
    cd "$HOME/src/$temp_dir"
    if ! git checkout "tags/$version_tag" 2>/dev/null; then
        echo -e "${RED}Error: Version tag '$version_tag' not found${NC}"
        echo -e "${YELLOW}Please check the repository for valid tags and try again${NC}"
        cd "$HOME/src"
        rm -rf "$temp_dir"
        sleep 3
        download_and_build "$step_num" "$total_steps"
        return
    fi
    
    # Initialize and update git submodules (required for Jito and some Agave versions)
    echo -e "${CYAN}Initializing git submodules...${NC}"
    git submodule update --init --recursive
    
    # Create versioned directory name
    local versioned_name="${client_name}-${version_tag}"
    
    echo -e "${GREEN}✅ Source code downloaded (version: $version_tag)${NC}"
    
    # Move to versioned directory
    cd "$HOME/src"
    if [ -d "$HOME/src/$versioned_name" ]; then
        echo -e "${YELLOW}Directory $versioned_name already exists. Removing old version...${NC}"
        rm -rf "$HOME/src/$versioned_name"
    fi
    mv "$temp_dir" "$versioned_name"
    
    # Update SELECTED_CLIENT to include version
    SELECTED_CLIENT="$versioned_name"
    
    echo ""
    echo -e "${CYAN}Building $versioned_name (this may take a while)...${NC}"
    
    cd "$HOME/src/$versioned_name"
    ./scripts/cargo-install-all.sh . --validator-only
    
    echo ""
    echo -e "${BOLD}${GREEN}✅ Build complete! 🎉${NC}"
    pause
}

# Step 5: Apply PATH and Symlink
apply_path_and_symlink() {
    local step_num=${1:-5}
    local total_steps=${2:-$TOTAL_STEPS}
    show_header
    show_progress "$step_num" "$total_steps"
   echo -e "${BOLD}${CYAN}🔗 STEP 5: APPLY PATH AND SYMLINK${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "This step creates a symlink ~/agave-current pointing to your"
    echo "installed validator client, making it easier to manage upgrades."
    echo ""
    read -p "Create symlink and update PATH? [Y/N]: " create_symlink
    
    if [[ "$create_symlink" =~ ^[Nn]$ ]]; then
        echo -e "${CYAN}Skipping symlink creation.${NC}"
        echo ""
        echo -e "${YELLOW}Note: You'll need to manually set your PATH to:${NC}"
        echo -e "${CYAN}  $HOME/src/$SELECTED_CLIENT/bin${NC}"
        pause
        return
    fi
    
    local client_dir="$HOME/src/$SELECTED_CLIENT/bin"
    
    echo ""
    echo -e "${CYAN}Checking for existing symlink...${NC}"
    
    # Check if agave-current exists (symlink or directory)
    if [ -e "$HOME/agave-current/bin" ] || [ -L "$HOME/agave-current/bin" ]; then
        if [ -L "$HOME/agave-current/bin" ]; then
            local current_target=$(readlink -f "$HOME/agave-current/bin")
            echo -e "  ${YELLOW}⚠️ Existing symlink found:${NC}"
            echo -e "    Current: ~/agave-current/bin -> $current_target"
        else
            echo -e "  ${YELLOW}⚠️ Existing directory/file found at ~/agave-current${NC}"
        fi
        
        echo -e "    New:     ~/agave-current/ -> $client_dir"
        echo ""
        echo "Options:"
        echo "  1) Keep existing and skip symlink creation"
        echo "  2) Replace with new symlink"
        echo ""
        read -p "Enter your choice [1-2]: " replace_choice
        
        case $replace_choice in
            1)
                echo -e "${CYAN}Keeping existing symlink/directory.${NC}"
                pause
                return
                ;;
            2)
                echo ""
                echo -e "${CYAN}Removing existing symlink/directory...${NC}"
                if [ -L "$HOME/agave-current/bin" ]; then
                    rm "$HOME/agave-current/bin"
                else
                    rm -rf "$HOME/agave-current/bin"
                fi
                echo -e "  ${GREEN}✅ Old symlink/directory removed${NC}"
                ;;
            *)
                echo -e "${RED}Invalid choice. Keeping existing.${NC}"
                pause
                return
                ;;
        esac
    fi
    
    echo -e "${CYAN}Creating symlink...${NC}"
    ln -s "$client_dir" "$HOME/agave-current"
    echo -e "  ${GREEN}✅ Symlink created: ~/agave-current/ -> $client_dir${NC}"
    echo -e "  ${GREEN}✅ Binaries accessible at: ~/agave-current/bin/${NC}"
    
    echo ""
    echo -e "${CYAN}Setting up PATH...${NC}"
    
    # Add to PATH in current session
    export PATH="$HOME/agave-current/bin:$PATH"
    
    # Add to .bashrc if not already there
    if ! grep -q "agave-current/bin" "$HOME/.bashrc"; then
        echo 'export PATH="$HOME/agave-current/bin:$PATH"' >> "$HOME/.bashrc"
        echo -e "  ${GREEN}✅ PATH added to ~/.bashrc${NC}"
    else
        echo -e "  ${GREEN}✅ PATH already in ~/.bashrc${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}${GREEN}✅ PATH and symlink configured! 🔗${NC}"
    pause
}

# Step 6: Cluster Set
cluster_set() {
    local step_num=${1:-6}
    show_header
    show_progress "$step_num" "$TOTAL_STEPS"
    echo -e "${BOLD}${CYAN}🌐 STEP 6: SOLANA CLUSTER SET${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "Select a Solana Cluster:"
    echo ""
    echo -e "  ${GREEN}1)${NC} Solana Mainnet-Beta (Production)"
    echo -e "  ${GREEN}2)${NC} Solana Testnet (Testing)"
    echo ""
    
    read -p "Enter your choice [1-2]: " cluster_choice
    
    case $cluster_choice in
        1)
            echo ""
            echo -e "${CYAN}Setting cluster to Mainnet-Beta...${NC}"
            solana config set --url https://api.mainnet-beta.solana.com
            SELECTED_CLUSTER="mainnet-beta"
            ;;
        2)
            echo ""
            echo -e "${CYAN}Setting cluster to Testnet...${NC}"
            solana config set --url https://api.testnet.solana.com
            SELECTED_CLUSTER="testnet"
            ;;
        *)
            echo -e "${RED}Invalid choice.${NC}"
            sleep 2
            cluster_set "$step_num"
            return
            ;;
    esac
    
    echo ""
    echo -e "${BOLD}${GREEN}✅ Cluster configured! 🌐${NC}"
    pause
}

# Step 7: Create Script
create_script() {
    local step_num=${1:-7}
    show_header
    show_progress "$step_num" "$TOTAL_STEPS"
    echo -e "${BOLD}${CYAN}📝 STEP 7: CREATE VALIDATOR SCRIPT${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ -f "$HOME/bin/validator.sh" ]; then
        echo -e "${YELLOW}validator.sh already exists.${NC}"
        echo ""
        read -p "Overwrite existing script? [Y/N]: " overwrite
        
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Skipping script creation.${NC}"
            pause
            return
        fi
    fi
    
    echo "This will create a validator.sh script with default values."
    echo ""
    read -p "Create validator.sh script? [Y/N]: " create_script_choice
    
    if [[ "$create_script_choice" =~ ^[Nn]$ ]]; then
        echo -e "${CYAN}Skipping script creation (manual configuration required).${NC}"
        pause
        return
    fi
    
    echo ""
    echo -e "${CYAN}Creating validator.sh script for $SELECTED_CLUSTER...${NC}"
    
    if [ "$SELECTED_CLUSTER" = "testnet" ]; then
        cat > "$HOME/bin/validator.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

BIN="$HOME/agave-current/bin/agave-validator"

export PATH="$HOME/agave-current/bin:$PATH"
exec "$BIN" \
    --identity "$HOME/validator-keypair.json" \
    --vote-account "$HOME/vote-account-keypair.json" \
    --log "$HOME/agave-validator.log" \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --known-validator 5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on \
    --known-validator 9QxCLckBiJc783jnMvXZubK4wH86Eqqvashtrwvcsgkv \
    --known-validator Ft5fbkqNa76vnsjYNwjDZUXoTWpP7VYm3mtsaQckQADN \
    --known-validator Go6oBjPpLVLsYtyodoaqLv7ey86bQvc3sLTbTKNGHZK7 \
    --known-validator eoKpUABi59aT4rR9HGS3LcMecfut9x7zJyodWWP43YQ \
    --known-validator J5BJHkRuGpWwfkm1Bxau6QFge4dTausFzdgvj3vzipuv \
    --known-validator wetfCN7bhjhBT8GTSAnah8ftoRoHB8H8Q87KkxDdRgK \
    --known-validator 3gZdC5xeQQSiVVw19RvyKADsfga5ov5XSyPpLjQv7b2y \
    --known-validator vnd1sXYmA8YY9xHQBkKKurZeq7iCe6EQ9bGYNZJwh1c \
    --known-validator axyaGn2eZM1dnDCagpd9aYa92gKWTrtEYb8vwc21ddr \
    --known-validator dedxpgLN1VXLHpekKra1JKkMGrw7tW1uuYz7Ec28iLK \
    --known-validator TBA2vCEUBPMCfVbxTWLstvyM3oqhg6bboYy24sBHEWX \
    --known-validator 36GzimUeoiBaapYaC1yriTJ9moQK1QvJfexppcZv3PaN \
    --rpc-port 8899 \
    --private-rpc \
    --dynamic-port-range 8000-8025 \
    --gossip-port 8001 \
    --entrypoint entrypoint.testnet.solana.com:8001 \
    --entrypoint entrypoint2.testnet.solana.com:8001 \
    --entrypoint entrypoint3.testnet.solana.com:8001 \
    --expected-genesis-hash 4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY \
    --block-verification-method=unified-scheduler \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size
EOF
    else
        cat > "$HOME/bin/validator.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

BIN="$HOME/agave-current/bin/agave-validator"

export PATH="$HOME/agave-current/bin:$PATH"
exec "$BIN" \
    --identity "$HOME/validator-keypair.json" \
    --vote-account "$HOME/vote-account-keypair.json" \
    --log "$HOME/agave-validator.log" \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \
    --known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \
    --known-validator DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ \
    --known-validator CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S \
    --only-known-rpc \
    --rpc-port 8899 \
    --private-rpc \
    --dynamic-port-range 8000-8025 \
    --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
    --expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size
EOF
    fi
    
    # Set permissions
    touch "$HOME/bin/validator.sh"
    chmod +x "$HOME/bin/validator.sh"
    
    echo -e "  ${GREEN}✅ validator.sh created and made executable${NC}"
    echo ""
    echo -e "${BOLD}${GREEN}✅ Validator script configured! 📝${NC}"
    pause
}

# Step 8: Create System Service
create_system_service() {
    local step_num=${1:-8}
    show_header
    show_progress "$step_num" "$TOTAL_STEPS"
    echo -e "${BOLD}${CYAN}⚙️  STEP 8: CREATE SYSTEM SERVICE${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ -f "/etc/systemd/system/sol.service" ]; then
        echo -e "${YELLOW}sol.service already exists.${NC}"
        echo ""
        read -p "Overwrite existing service? [Y/N]: " overwrite
        
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Skipping service creation.${NC}"
            pause
            return
        fi
    fi
    
    echo "This will create a systemd service to run the validator automatically."
    echo ""
    read -p "Create sol.service? [Y/N]: " create_service_choice
    
    if [[ "$create_service_choice" =~ ^[Nn]$ ]]; then
        echo -e "${CYAN}Skipping service creation (manual configuration required).${NC}"
        pause
        return
    fi
    
    echo ""
    echo -e "${CYAN}Creating sol.service (requires sudo)...${NC}"
    
    sudo bash -c "cat >/etc/systemd/system/sol.service <<EOF
[Unit]
Description=Solana Validator
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/
LogRateLimitIntervalSec=0
Restart=always
RestartSec=3
LimitNOFILE=1000000
LimitMEMLOCK=2000000000
Environment=PATH=$HOME/agave-current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin
TasksMax=infinity
ExecStartPre=/usr/bin/test -x $HOME/bin/validator.sh
ExecStartPre=/usr/bin/test -x $HOME/agave-current/bin/agave-validator
ExecStartPre=/usr/bin/test -d /mnt/ledger
ExecStartPre=/usr/bin/test -d /mnt/accounts
ExecStart=$HOME/bin/validator.sh

[Install]
WantedBy=multi-user.target
EOF"
    
    echo -e "  ${GREEN}✅ Service file created${NC}"
    echo ""
    echo -e "${CYAN}Enabling sol.service...${NC}"
    
    sudo systemctl enable sol
    
    echo -e "  ${GREEN}✅ Service enabled${NC}"
    echo ""
    echo -e "${BOLD}${GREEN}✅ System service configured! ⚙️${NC}"
    echo ""
    echo -e "${YELLOW}Note: The service is enabled but not started. You can start it later with:${NC}"
    echo -e "${CYAN}  sudo systemctl start sol${NC}"
    pause
}

# Step 9: Linux System Tuning
linux_system_tuning() {
    local step_num=${1:-9}
    show_header
    show_progress "$step_num" "$TOTAL_STEPS"
    echo -e "${BOLD}${CYAN}🔧 STEP 9: LINUX SYSTEM TUNING${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "Checking if Linux tuning configuration is already applied..."
    echo ""
    
    local tuning_needed=false
    local checks_failed=()
    
    # Check 1: Sysctl settings
    echo -e "${CYAN}Checking sysctl settings...${NC}"
    if [ -f "/etc/sysctl.d/21-agave-validator.conf" ]; then
        local rmem_max=$(sysctl -n net.core.rmem_max 2>/dev/null || echo "0")
        local wmem_max=$(sysctl -n net.core.wmem_max 2>/dev/null || echo "0")
        local max_map_count=$(sysctl -n vm.max_map_count 2>/dev/null || echo "0")
        local nr_open=$(sysctl -n fs.nr_open 2>/dev/null || echo "0")
        
        if [ "$rmem_max" -eq 134217728 ] && [ "$wmem_max" -eq 134217728 ] && \
           [ "$max_map_count" -eq 1000000 ] && [ "$nr_open" -eq 1000000 ]; then
            echo -e "  ${GREEN}✅ Sysctl settings correctly configured${NC}"
        else
            echo -e "  ${YELLOW}⚠️ Sysctl settings need adjustment${NC}"
            tuning_needed=true
            checks_failed+=("sysctl")
        fi
    else
        echo -e "  ${YELLOW}⚠️ Sysctl config file not found${NC}"
        tuning_needed=true
        checks_failed+=("sysctl")
    fi
    
    # Check 2: Service limits
    echo -e "${CYAN}Checking systemd service limits...${NC}"
    if [ -f "/etc/systemd/system/sol.service" ]; then
        if grep -q "LimitNOFILE=1000000" /etc/systemd/system/sol.service && \
           grep -q "LimitMEMLOCK=2000000000" /etc/systemd/system/sol.service; then
            echo -e "  ${GREEN}✅ Service limits correctly configured${NC}"
        else
            echo -e "  ${YELLOW}⚠️ Service limits need adjustment${NC}"
            tuning_needed=true
            checks_failed+=("service_limits")
        fi
    else
        echo -e "  ${YELLOW}⚠️ sol.service not found${NC}"
    fi
    
    # Check 3: System limits
    echo -e "${CYAN}Checking system limits configuration...${NC}"
    if [ -f "/etc/security/limits.d/90-solana-nofiles.conf" ]; then
        if grep -q "nofile 1000000" /etc/security/limits.d/90-solana-nofiles.conf && \
           grep -q "memlock 2000000" /etc/security/limits.d/90-solana-nofiles.conf; then
            echo -e "  ${GREEN}✅ System limits correctly configured${NC}"
        else
            echo -e "  ${YELLOW}⚠️ System limits need adjustment${NC}"
            tuning_needed=true
            checks_failed+=("system_limits")
        fi
    else
        echo -e "  ${YELLOW}⚠️ System limits config file not found${NC}"
        tuning_needed=true
        checks_failed+=("system_limits")
    fi
    
    # Check 4: CPU governor
    echo -e "${CYAN}Checking CPU governor...${NC}"
    local governors=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort -u)
    if echo "$governors" | grep -q "performance" && [ $(echo "$governors" | wc -l) -eq 1 ]; then
        echo -e "  ${GREEN}✅ CPU governor set to performance mode${NC}"
    else
        echo -e "  ${YELLOW}⚠️ CPU governor not set to performance mode${NC}"
        tuning_needed=true
        checks_failed+=("cpu_governor")
    fi
    
    echo ""
    
    if [ "$tuning_needed" = false ]; then
        echo -e "${BOLD}${GREEN} ✅ All Linux tuning configurations are already applied! 🔧${NC}"
        pause
        return 0
    fi
    
    # Show what needs to be fixed
    echo -e "${YELLOW}The following configurations need to be applied:${NC}"
    for check in "${checks_failed[@]}"; do
        echo "  - $check"
    done
    echo ""
    
    read -p "Apply Linux system tuning now? [Y/n]: " apply_tuning
    
    if [[ "$apply_tuning" =~ ^[Nn]$ ]]; then
        echo -e "${CYAN}Skipping system tuning.${NC}"
        pause
        return
    fi
    
    # Apply tuning configurations
    echo ""
    
    # Stage a: Optimize sysctl knobs
    if [[ " ${checks_failed[@]} " =~ " sysctl " ]]; then
        echo -e "${CYAN}Stage 1/4: Optimizing sysctl knobs...${NC}"
        
        sudo bash -c 'cat >/etc/sysctl.d/21-agave-validator.conf <<EOF
# Increase max UDP buffer sizes
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728

# Increase memory mapped files limit
vm.max_map_count = 1000000

# Increase number of allowed open file descriptors
fs.nr_open = 1000000
EOF'
        
        sudo sysctl -p /etc/sysctl.d/21-agave-validator.conf
        echo -e "  ${GREEN}✅ Sysctl settings applied${NC}"
        echo ""
    fi
    
    # Stage b: Verify sol.service limits
    if [[ " ${checks_failed[@]} " =~ " service_limits " ]]; then
        echo -e "${CYAN}Stage 2/4: Configuring systemd service limits...${NC}"
        
        if [ -f "/etc/systemd/system/sol.service" ]; then
            # Backup the service file
            sudo cp /etc/systemd/system/sol.service /etc/systemd/system/sol.service.backup
            
            # Ensure limits are present
            if ! grep -q "LimitNOFILE" /etc/systemd/system/sol.service; then
                sudo sed -i '/\[Service\]/a LimitNOFILE=1000000' /etc/systemd/system/sol.service
            fi
            
            if ! grep -q "LimitMEMLOCK" /etc/systemd/system/sol.service; then
                sudo sed -i '/\[Service\]/a LimitMEMLOCK=2000000000' /etc/systemd/system/sol.service
            fi
            
            sudo systemctl daemon-reload
            echo -e "  ${GREEN}✅ Service limits configured and daemon reloaded${NC}"
        else
            echo -e "  ${YELLOW}⚠️ sol.service not found, skipping this step${NC}"
        fi
        echo ""
    fi
    
    # Stage c: Raise count limits
    if [[ " ${checks_failed[@]} " =~ " system_limits " ]]; then
        echo -e "${CYAN}Stage 3/4: Raising system count limits...${NC}"
        
        sudo bash -c 'cat >/etc/security/limits.d/90-solana-nofiles.conf <<EOF
# Increase process file descriptor count limit
* - nofile 1000000
# Increase memory locked limit (kB)
* - memlock 2000000
EOF'
        
        echo -e "  ${GREEN}✅ Count limits configured${NC}"
        echo ""
    fi
    
    # Stage d: Set CPU in Performance Mode
    if [[ " ${checks_failed[@]} " =~ " cpu_governor " ]]; then
        echo -e "${CYAN}Stage 4/4: Setting CPU to Performance Mode...${NC}"
        
        echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
        echo -e "  ${GREEN}✅ CPU governor set to performance mode${NC}"
        echo ""
    fi
    
    echo -e "${BOLD}${GREEN}✅ Linux system tuning complete! 🔧${NC}"
    echo ""
    echo -e "${YELLOW}Note: Some changes will take effect after reboot.${NC}"
    pause
}

# Step 10: Quit Tool
quit_tool() {
    clear
    echo ""
    echo -e "${BOLD}${GREEN}Thanks for using Rancho Stake's Solana Validator Tool! 🤠🥩"
    echo ""
    exit 0
}

# Simple Install - Main execution flow
simple_install() {
    # Step 1: Disk Check
    disk_check 1
    
    # Step 2: Directory Check
    directory_check 2
    
    # Step 3: Dependencies Check
    dependencies_check 3
    
    # Step 4: Download and Build
    download_and_build 4
    
    # Step 5: Apply PATH and Symlink
    apply_path_and_symlink 5
    
    # Step 6: Cluster Set
    cluster_set 6
    
    # Step 7: Create Script
    create_script 7
    
    # Step 8: Create System Service
    create_system_service 8
    
    # Step 9: Linux System Tuning
    linux_system_tuning 9
    
    # Final screen
    show_header
       echo -e "${BOLD}${GREEN}🎉 Setup Complete! 🎉${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "Your Solana validator is now configured!"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo -e "  1. Generate your validator keypairs:"
    echo -e "     ${BLUE}solana-keygen new -o ~/validator-keypair.json${NC}"
    echo -e "     ${BLUE}solana-keygen new -o ~/vote-account-keypair.json${NC}"
    echo ""
    echo -e "  2. Start your validator:"
    echo -e "     ${BLUE}sudo systemctl start sol${NC}"
    echo ""
    echo -e "  3. Check validator status:"
    echo -e "     ${BLUE}sudo systemctl status sol${NC}"
    echo ""
    echo -e "  4. View validator logs:"
    echo -e "     ${BLUE}tail -f ~/agave-validator.log${NC}"
    echo ""
    pause
    
    welcome_screen
}

# Main execution flow
main() {
    # Welcome screen
    welcome_screen
    
    # If we get here, user chose Simple Install
    simple_install
}

# Run main function
main
