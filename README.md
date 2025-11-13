# Rancho Stake's Solana Validator Tool

**An automated setup and updating tool for Solana validators**

[Website](https://ranchostake.xyz) • [Documentation](#usage) • [Contributing](#contributing)

</div>

## 📋 Overview

This script automates the setup and configuration of Solana validator nodes using either the Agave (official) or Jito (MEV-optimized) clients. It handles everything from system checks to service configuration.

## ✨ Features

### Installation Modes
- 🚀 **Simple Install** - Complete guided installation (all 9 steps)
- ℹ️ **Advanced Install** - Run specific steps individually
- 🔄 **Update Mode** - Quick validator client updates

### Smart Automation
- ✅ Automated disk and directory checks
- 📦 Dependency management (Rust, Anchor, system packages)
- 🔨 Automated building from source (Agave or Jito)
- 🔗 Symlink management for easy version switching
- 🌐 Cluster configuration (Mainnet/Testnet)
- 🤖 Validator script and systemd service creation
- ⚡ Linux system tuning with pre-flight checks

## 🎯 Prerequisites

### System Requirements
**CPU:**
- 2.8GHz base clock speed, or faster
- AMD Gen 3 or newer / Intel Ice Lake or newer
    - Higher clock speed is preferable over more cores
    - 12 cores / 24 threads, or more
**RAM:**
- 256GB or more (RAM	Error Correction Code (ECC) memory is suggested)

### Required Mounts
The script expects for 2x NVMe drives (formatted as ext4 or xfs) as two mount points:
- `/mnt/ledger` - For blockchain ledger data
- `/mnt/accounts` - For account state data

These must be configured in `/etc/fstab` with UUIDs for persistence before running the script.

## 🚀 Quick Start

### 1. Download the Script
```bash
wget https://raw.githubusercontent.com/RanchoStake/SolanaValidatorTool/main/solana-validator-tool.sh
```

### 2. Make it Executable
```bash
chmod +x solana-validator-tool.sh
```

### 3. Run the Setup
```bash
./solana-validator-tool.sh
```

### 4. Follow the Prompts
The script will guide you through:
- System compatibility checks
- Installation mode selection
- Client and version selection
- Configuration steps

## 📖 Usage

### Simple Install (Recommended for First-Time Setup)
1. Select option `1` from the main menu
2. Follow the prompts through all 9 steps
3. Estimated time: ~30 minutes

### Advanced Install (For Troubleshooting or Partial Setup)
1. Select option `2` from the main menu
2. Choose specific steps to run
3. Return to menu after each step

### Update Mode (For Existing Installations)
1. Select option `3` from the main menu
2. Choose new client version
3. Optionally restart validator service

## 📝 Installation Steps

The setup process includes 9 steps:

1. **Disk Check** - Validates storage configuration
2. **Directory Check** - Creates required directories
3. **Dependencies Check** - Installs Rust, Anchor, and system packages (3-5 min)
4. **Download and Build** - Clones and compiles validator client (8-10 min)
5. **PATH and Symlink** - Configures system paths
6. **Cluster Set** - Selects Mainnet or Testnet
7. **Create Script** - Generates validator.sh startup script
8. **Create Service** - Sets up systemd service
9. **System Tuning** - Applies Linux optimizations

## 🔧 Post-Installation

After successful installation:

### Generate Keypairs
```bash
# Validator identity
solana-keygen new -o ~/validator-keypair.json

# Vote account
solana-keygen new -o ~/vote-account-keypair.json
```

### Start Validator
```bash
sudo systemctl start sol
```

### Check Status
```bash
# Service status
sudo systemctl status sol

# Validator logs
tail -f ~/agave-validator.log

# Catchup status
solana catchup --our-localhost
```

### NOTE: If other filenames and/or directory structures are prefered for keystores and logs, you can change these values in `~/bin/validator.sh`.

## 🗂 Directory Structure

The script creates the following structure:
```
$HOME/
├── agave-current/        # Symlink to active validator version
├── src/
│   └── agave-v3.0.10/   # Versioned client installations
├── bin/
│   └── validator.sh      # Validator startup script
├── validator-keypair.json
├── vote-account-keypair.json
└── agave-validator.log

/mnt/
├── ledger/              # Blockchain ledger data
└── accounts/            # Account state data
```

## 🤝 Contributing

Rancho Stake's Solana Validator Tool was vibe coded out of the need to simplify validator operations, so any ideas to improve the script are more than welcome!

### Contribution Guidelines

1. **Code Style**
   - Use consistent indentation (4 spaces)
   - Add comments for complex logic
   - Follow existing function naming patterns

2. **Testing**
   - Test all three installation modes
   - Testing for both Agave and Jito clients are appreciated!

3. **Documentation**
   - Update CHANGELOG.md for all changes
   - Add inline comments for new functions
   - Update README if adding features

4. **Pull Requests**
   - Provide clear description of changes
   - Reference any related issues
   - Include testing results

### Areas for Contribution

- 🐛 Bug fixes and error handling
- 📝 Documentation improvements
- 🎨 UI/UX enhancements
- ⚡ Performance optimizations
- 🔨 MKFS or similar formatting tool integration for disks check
- 🔧 Additional system checks like XDP

- Vibecoded by [Rancho Stake](https://ranchostake.xyz) 🤠🥩 with the help of [Claude.AI](https://claude.ai) 🤖
- Built for the general Solana validator community

## 🔗 Links

- **Website**: https://ranchostake.xyz
- **GitHub**: https://github.com/RanchoStake/SolanaValidatorTool
- **Solana Docs**: https://docs.solana.com
- **Agave GitHub**: https://github.com/anza-xyz/agave
- **Jito GitHub**: https://github.com/jito-foundation/jito-solana

---

**Made from 🇲🇽 with ❤️ by Rancho Stake**


</div>
