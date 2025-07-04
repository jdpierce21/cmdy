package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"gopkg.in/yaml.v3"
)

type MenuOption struct {
	Display  string            `yaml:"display"`
	Commands map[string]string `yaml:"commands"`
}


func runFzf(options []MenuOption) (string, error) {
	var b strings.Builder
	b.Grow(len(options) * 32) // Estimate capacity
	for i, option := range options {
		if i > 0 {
			b.WriteByte('\n')
		}
		b.WriteString(option.Display)
	}

	cmd := exec.Command("fzf", "--header=Select an option:", "--height=~50%", "--layout=reverse")
	cmd.Stdin = strings.NewReader(b.String())
	cmd.Stderr = os.Stderr

	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func discoverScripts() []MenuOption {
	var discovered []MenuOption
	scriptsDir := "scripts"
	
	files, err := os.ReadDir(scriptsDir)
	if err != nil {
		return discovered // Return empty if scripts dir doesn't exist
	}
	
	currentOS := runtime.GOOS
	if currentOS == "darwin" {
		currentOS = "mac"
	}
	
	for _, file := range files {
		if file.IsDir() || !isExecutable(filepath.Join(scriptsDir, file.Name())) {
			continue
		}
		
		name := strings.TrimSuffix(file.Name(), filepath.Ext(file.Name()))
		scriptPath := "./" + filepath.Join(scriptsDir, file.Name())
		
		option := MenuOption{
			Display: name,
			Commands: map[string]string{
				"linux":   scriptPath,
				"mac":     scriptPath,
				"windows": scriptPath,
			},
		}
		discovered = append(discovered, option)
	}
	
	return discovered
}

func isExecutable(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return info.Mode()&0111 != 0 // Check if any execute bit is set
}

func mergeOptions(config []MenuOption, discovered []MenuOption) []MenuOption {
	// Create set of script paths already in config
	configPaths := make(map[string]bool)
	for _, option := range config {
		for _, cmd := range option.Commands {
			if strings.HasPrefix(cmd, "./scripts/") {
				configPaths[cmd] = true
			}
		}
	}
	
	// Add discovered scripts that aren't already in config
	merged := append([]MenuOption{}, config...)
	for _, option := range discovered {
		scriptPath := option.Commands["linux"] // All OS use same path
		if !configPaths[scriptPath] {
			merged = append(merged, option)
		}
	}
	
	return merged
}

func executeCommand(command string) error {
	cmd := exec.Command("sh", "-c", command)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// Old main function moved to runInteractiveMenu above

func showUsage() {
	fmt.Println("cmdy - Modern CLI Command Assistant")
	fmt.Println("")
	fmt.Println("Usage:")
	fmt.Println("  cmdy           Run interactive menu")
	fmt.Println("  cmdy build     Build the binary")
	fmt.Println("  cmdy install   Install/update globally")
	fmt.Println("  cmdy dev [msg] Commit, push, and install (dev workflow)")
	fmt.Println("  cmdy update    Pull latest and rebuild")
	fmt.Println("  cmdy version   Show current version")
	fmt.Println("  cmdy config    Edit config file")
	fmt.Println("  cmdy help      Show this help")
}

func buildCmdy() {
	fmt.Println("Building cmdy...")
	cmd := exec.Command("go", "build", "-ldflags=-s -w", "-o", "cmdy", "main.go")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("Build failed: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("✓ Build completed: ./cmdy")
}

func installCmdy() {
	fmt.Println("Installing cmdy globally...")
	
	// Build first
	buildCmdy()
	
	// Determine install location
	homeDir, _ := os.UserHomeDir()
	installPath := filepath.Join(homeDir, ".local", "bin", "cmdy")
	
	// Create directory if needed
	os.MkdirAll(filepath.Dir(installPath), 0755)
	
	// Copy binary
	src, err := os.Open("cmdy")
	if err != nil {
		fmt.Printf("Failed to open binary: %v\n", err)
		os.Exit(1)
	}
	defer src.Close()
	
	dst, err := os.Create(installPath)
	if err != nil {
		fmt.Printf("Failed to create install target: %v\n", err)
		os.Exit(1)
	}
	defer dst.Close()
	
	_, err = io.Copy(dst, src)
	if err != nil {
		fmt.Printf("Failed to copy binary: %v\n", err)
		os.Exit(1)
	}
	
	// Make executable
	os.Chmod(installPath, 0755)
	
	fmt.Printf("✓ Installed to %s\n", installPath)
	fmt.Println("Make sure ~/.local/bin is in your PATH")
}

func devWorkflow() {
	msg := "Update cmdy"
	if len(os.Args) > 2 {
		msg = strings.Join(os.Args[2:], " ")
	}
	
	fmt.Println("Running dev workflow...")
	
	// Git add
	fmt.Println("Staging changes...")
	cmd := exec.Command("git", "add", ".")
	if err := cmd.Run(); err != nil {
		fmt.Printf("Git add failed: %v\n", err)
		os.Exit(1)
	}
	
	// Git commit
	fmt.Printf("Committing: %s\n", msg)
	cmd = exec.Command("git", "commit", "-m", msg)
	cmd.Stdout = os.Stdout
	if err := cmd.Run(); err != nil {
		fmt.Printf("Git commit failed: %v\n", err)
		os.Exit(1)
	}
	
	// Git push
	fmt.Println("Pushing to origin...")
	cmd = exec.Command("git", "push", "origin", "master")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("Git push failed: %v\n", err)
		os.Exit(1)
	}
	
	// Install
	installCmdy()
	
	fmt.Println("✓ Dev workflow completed!")
}

func updateCmdy() {
	fmt.Println("Updating cmdy...")
	
	// Git pull
	fmt.Println("Pulling latest changes...")
	cmd := exec.Command("git", "pull", "origin", "master")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("Git pull failed: %v\n", err)
		os.Exit(1)
	}
	
	// Build and install
	installCmdy()
	
	fmt.Println("✓ Update completed!")
}

func showVersion() {
	cmd := exec.Command("git", "rev-parse", "--short", "HEAD")
	output, err := cmd.Output()
	if err != nil {
		fmt.Println("Version: unknown (not in git repo)")
		return
	}
	fmt.Printf("cmdy version: %s\n", strings.TrimSpace(string(output)))
}

func editConfig() {
	configPath := "config.yaml"
	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "nano" // fallback
	}
	
	cmd := exec.Command(editor, configPath)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		fmt.Printf("Failed to open editor: %v\n", err)
	}
}

func runInteractiveMenu() {
	data, err := os.ReadFile("config.yaml")
	if err != nil {
		log.Fatal(err)
	}

	var config struct {
		MenuOptions []MenuOption `yaml:"menu_options"`
	}
	if err := yaml.Unmarshal(data, &config); err != nil {
		log.Fatal(err)
	}

	// Auto-discover scripts and merge with config
	discovered := discoverScripts()
	allOptions := mergeOptions(config.MenuOptions, discovered)
	
	if len(allOptions) == 0 {
		log.Fatal("no menu options configured and no scripts found")
	}

	currentOS := runtime.GOOS
	if currentOS == "darwin" {
		currentOS = "mac"
	}

	optionMap := make(map[string]*MenuOption, len(allOptions))
	for i := range allOptions {
		optionMap[allOptions[i].Display] = &allOptions[i]
	}

	for {
		selected, err := runFzf(allOptions)
		if err != nil || selected == "" {
			break
		}

		if option, exists := optionMap[selected]; exists {
			if command, hasCommand := option.Commands[currentOS]; hasCommand {
				if err := executeCommand(command); err != nil {
					fmt.Printf("Error: %v\n", err)
				}
			}
		}
	}
}

func main() {
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "build":
			buildCmdy()
		case "install":
			installCmdy()
		case "dev":
			devWorkflow()
		case "update":
			updateCmdy()
		case "version":
			showVersion()
		case "config":
			editConfig()
		case "help", "--help", "-h":
			showUsage()
		default:
			fmt.Printf("Unknown command: %s\n\n", os.Args[1])
			showUsage()
			os.Exit(1)
		}
		return
	}
	
	// No arguments - run interactive menu
	runInteractiveMenu()
}

