package main

import (
	"fmt"
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

func main() {
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

