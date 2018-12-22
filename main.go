package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"encoding/csv"
	"io"
	"strings"
	"strconv"

	"github.com/containerd/cgroups"
	specs "github.com/opencontainers/runtime-spec/specs-go"
)

func main() {
	var (
		cpu     = flag.Int("cpu", 30, "cpu limit(%)")
		memory  = flag.Int64("memory", 512*1024*1024, "memory limit(bytes)")
		pids    = flag.String("pids", "", "pids(comma separate)")
		group   = flag.String("group", "grcon", "cgroups path")
		user    = flag.String("user", "", "exec username")
		command = flag.String("command", "", "exec command")
	)
	flag.Parse()

	if len(*command) == 0 && len(*pids) == 0 {
		fmt.Println("command or pids not found: --command or --pids")
		os.Exit(1)
	}

	if len(*command) > 0 && len(*pids) > 0 {
		fmt.Println("don't use both --command and --pids")
		os.Exit(1)
	}

	if len(*user) > 0 && len(*pids) > 0 {
		fmt.Println("don't use both --user and --pids")
		os.Exit(1)
	}

	if len(*user) == 0 && len(*pids) == 0 {
		fmt.Println("user not found: --user")
		os.Exit(1)
	}

	quota := int64(*cpu) * 1000
	limit := int64(*memory)
	control, err := cgroups.New(cgroups.V1, cgroups.StaticPath(fmt.Sprintf("/%s", *group)), &specs.LinuxResources{
		CPU: &specs.LinuxCPU{
			Quota: &quota,
		},
		Memory: &specs.LinuxMemory{
			Limit: &limit,
		},
	})

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	defer control.Delete()

	if len(*pids) > 0 {
		r := csv.NewReader(strings.NewReader(*pids))

		for {
			record, err := r.Read()
			if err == io.EOF {
				break
			}

			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}

			for i := 0; i < len(record); i++ {
				pid, err := strconv.Atoi(record[i])
				if err != nil {
					fmt.Println(err)
					os.Exit(1)
				}

				if err := control.Add(cgroups.Process{Pid: pid}); err != nil {
					fmt.Println(err)
					os.Exit(1)
				}
			}
		}
	} else {
		if err := control.Add(cgroups.Process{Pid: os.Getpid()}); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		out, err := exec.Command("sh", "-c", fmt.Sprintf("sudo -u %s %s", *user, *command)).Output()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		fmt.Print(string(out))
	}
}
