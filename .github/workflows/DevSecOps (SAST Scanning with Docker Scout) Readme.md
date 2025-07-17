Explanation and Key Concepts:
• GitHub Workflows (.github/workflows/): GitHub Actions workflows are defined in YAML files placed in the .github/workflows/ directory of your repository. When you push this file, GitHub automatically detects and runs the workflow.
• on: push Trigger: This configures the workflow to run automatically whenever new code is pushed to your repository. This provides fast feedback on potential security issues introduced by new changes.
• Jobs and Parallel Execution: The workflow defines two independent jobs (sast-scan and image-scan). These jobs can run in parallel by default, which saves time in your pipeline.
• runs-on: ubuntu-latest: Each job specifies the operating system environment where its steps will be executed. ubuntu-latest provides a fresh, isolated virtual machine for each job.
• actions/checkout@v2: This is a common GitHub Action that checks out your repository's code into the runner, making it available for subsequent steps.
• Static Application Security Testing (SAST) with Bandit:
    ◦ Purpose: SAST tools analyze your source code without executing it to find potential vulnerabilities, such as SQL injection patterns or hardcoded secrets.
    ◦ Bandit: A popular SAST tool specifically for Python applications.
    ◦ Configuration (--sev, --conf): The provided configuration  --sev medium,high --conf medium,high is crucial for managing the output. It tells Bandit to only report issues with medium or high severity and medium or high confidence. This helps reduce the "noise" of hundreds of low-priority findings, making the results more actionable for developers.
• Docker Image Scanning with Docker Scout:
    ◦ Purpose: Docker images, being composed of layers (base OS, installed packages, libraries), can contain vulnerabilities. Image scanning identifies these issues, allowing you to use more secure, leaner images.
    ◦ Docker Scout: A Docker-native tool that performs thorough scanning of image layers.
    ◦ exit-code: true: This is a powerful feature that makes the job fail if vulnerabilities are found. This breaks the build, preventing insecure images from proceeding further in your deployment pipeline.
• Artifact Upload (actions/upload-artifact@v2):
    ◦ Purpose: Scan results are generated as files (e.g., bandit-report.json, scout-report.sarif). Uploading them as artifacts makes them available for download and review after the workflow run, even if the job machine is ephemeral.
    ◦ if: always(): This conditional execution ensures that the reports are uploaded regardless of whether the scan step succeeded or failed. This is vital because you want to capture and analyze the findings even when vulnerabilities cause the scan to fail.
    ◦ Vulnerability Management Tools: These reports (JSON, SARIF) are formatted for machine consumption and can be imported into vulnerability management tools like Defect Dojo. These tools provide a centralized UI to visualize, analyze, and manage security findings across multiple scans and tools, making it easier for teams to track and prioritize fixes.
• GitHub Secrets: Sensitive information, such as your Docker Hub credentials, should never be hardcoded directly into your workflow files. Instead, they should be stored securely as GitHub Secrets, which are then referenced as environment variables in your workflow steps (${{ secrets.DOCKER_USER }}).
This workflow provides a solid foundation for integrating DevSecOps practices into your GitHub repository, automating critical security checks early in your development process.
