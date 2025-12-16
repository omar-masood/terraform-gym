# Terraform Docker Exercise

## Before You Start

The exercise requires Docker-in-Docker support. **You must sync your fork and rebuild your Codespace** before starting.

### Step 1: Sync Your Fork

1. Go to your fork of `terraform-gym` on GitHub
2. Click **Sync fork** → **Update branch**
3. Your fork now has the latest devcontainer config with Docker support

### Step 2: Rebuild Your Codespace

1. Open your Codespace
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Type: **Codespaces: Rebuild Container**
4. Select it and wait for the rebuild (~2-3 minutes)

### Step 3: Verify Docker Works

After rebuild, test that Docker is available:

```bash
docker ps
```

You should see an empty container list (not an error). If you get "command not found" or "cannot connect", the rebuild didn't work.

---

## The Exercise

Navigate to the Docker exercise:

```bash
cd exercises/docker
```

Open `LAB.md` and follow the instructions.

**What you'll build:**
- A Docker network
- An nginx container (web server)
- A redis container (cache)
- All connected and communicating

**Time:** 30-45 minutes

**No cloud credentials needed** - everything runs locally in your Codespace.

---

## Tips

1. **Read the docs** - Links are in LAB.md
2. **Test with `terraform plan`** - See what will be created before applying
3. **Check your work** - Use `docker ps` and `docker network ls` to verify
4. **The lab has a trick** - Pay attention to the resource count hint 😉

---

## If You Get Stuck

- Check the hints in LAB.md (expandable sections)
- Re-read the Terraform Docker provider docs
- Ask for help after trying for 10+ minutes

Good luck! 🐳
