docker stats --format "table [{{.Name}}]\nCPU: {{.CPUPerc}}\nMEM: {{.MemUsage}}\n"