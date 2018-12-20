package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"pkg/mod/github.com/opencontainers/runtime-spec@v1.0.1/specs-go"

	"github.com/containerd/cgroups"
)

func main() {
	var (
		cpu = flag.Int("cpu", 30, "cpu")
		memory = flag.Int64("memory", 512 * 1024 * 1024, "memory")
		user = flag.String("user", "", "user")
		command = flag.String("command", "", "command")
	)
	flag.Parse()

	fmt.Println(*cpu)
	fmt.Println(*memory)
	fmt.Println(*command)
	fmt.Println(*user)
	if len(*command) == 0 {
		fmt.Println("command not found: --command [command]")
		os.Exit(1)
	}
	if len(*user) == 0 {
		fmt.Println("user not found: --user [username]")
		os.Exit(1)
	}

	pid := os.Getpid
	fmt.Printf("プロセスID: %d\n", pid)

	shares := uint64(*cpu)
	control, err := cgroups.New(cgroups.V1, cgroups.StaticPath("/grcon"), &specs.LinuxResources{
		CPU: &specs.CPU{
			Shares: &shares,
		},
	})
	defer control.Delete()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if err := control.Add(cgroups.Process{Pid:pid}); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	sudoCommand := fmt.Sprintf("sudo -u %s %s", *user, *command)
	fmt.Println(sudoCommand)
	cmd := exec.Command("sh", "-c", sudoCommand)
	out, err := cmd.Output()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Print(string(out))
}
