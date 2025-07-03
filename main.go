package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"gopkg.in/yaml.v3"
)

type MenuOption struct {
	Shortcut    string            `yaml:"shortcut"`
	Name        string            `yaml:"name"`
	Description string            `yaml:"description"`
	Commands    map[string]string `yaml:"commands"`
}

type Config struct {
	MenuOptions []MenuOption `yaml:"menu_options"`
}

func getOS() string {
	osType := strings.ToLower(runtime.GOOS)
	// Map darwin to mac for user-friendly config
	if osType == "darwin" {
		return "mac"
	}
	return osType
}

func loadConfig(configPath string) (*Config, error) {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	return &config, nil
}

func createFzfInput(options []MenuOption) string {
	var lines []string
	for _, option := range options {
		line := fmt.Sprintf("[%s] %s - %s", option.Shortcut, option.Name, option.Description)
		lines = append(lines, line)
	}
	return strings.Join(lines, "\n")
}

func runFzf(input string) (string, error) {
	cmd := exec.Command("fzf", "--header=Select an option:", "--height=~50%", "--layout=reverse")
	cmd.Stdin = strings.NewReader(input)
	cmd.Stderr = os.Stderr

	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("fzf failed: %w", err)
	}

	return strings.TrimSpace(string(output)), nil
}

func extractShortcut(selected string) string {
	if strings.HasPrefix(selected, "[") {
		end := strings.Index(selected, "]")
		if end > 1 {
			return selected[1:end]
		}
	}
	return ""
}

func executeCommand(command string) error {
	if command == "exit" {
		os.Exit(0)
	}

	cmd := exec.Command("sh", "-c", command)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

func runMenu() error {
	config, err := loadConfig("config.yaml")
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	if len(config.MenuOptions) == 0 {
		return fmt.Errorf("no menu options configured")
	}

	currentOS := getOS()
	
	for {
		fzfInput := createFzfInput(config.MenuOptions)
		selected, err := runFzf(fzfInput)
		
		if err != nil {
			// User cancelled (Ctrl+C or ESC)
			break
		}

		if selected == "" {
			break
		}

		shortcut := extractShortcut(selected)
		if shortcut == "" {
			continue
		}

		if shortcut == "q" {
			break
		}

		// Find the selected option
		var selectedOption *MenuOption
		for _, option := range config.MenuOptions {
			if option.Shortcut == shortcut {
				selectedOption = &option
				break
			}
		}

		if selectedOption == nil {
			fmt.Printf("Invalid option: %s\n", shortcut)
			continue
		}

		command, exists := selectedOption.Commands[currentOS]
		if !exists {
			fmt.Printf("No command configured for %s\n", currentOS)
			continue
		}

		if err := executeCommand(command); err != nil {
			fmt.Printf("Failed to execute command: %v\n", err)
		}
	}

	return nil
}

func main() {
	if err := runMenu(); err != nil {
		log.Fatal(err)
	}
}