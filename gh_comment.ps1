function Show-GhPrComments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Number,
        # Optional: owner/repo like "devolutions/cool-repo".
        [string]$Repo
    )

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "GitHub CLI (gh) not found. Install it and run `gh auth status`."
    }

    if (-not $Repo) {
        $Repo = gh repo view --json nameWithOwner --jq .nameWithOwner
        if (-not $Repo) { throw "Can't determine repo here. Pass -Repo 'owner/name'." }
    }

    # Top-level (issue) comments
    $issueComments = gh api "repos/$Repo/issues/$Number/comments?per_page=100" | ConvertFrom-Json
    if (-not $issueComments) { $issueComments = @() }

    # Inline review comments (file/line)
    $inlineComments = gh api "repos/$Repo/pulls/$Number/comments?per_page=100" | ConvertFrom-Json
    if (-not $inlineComments) { $inlineComments = @() }

    # Review summaries (Approve/Comment/Request changes with optional body)
    $reviews = gh api "repos/$Repo/pulls/$Number/reviews?per_page=100" | ConvertFrom-Json
    if (-not $reviews) { $reviews = @() }

    $all = @()

    foreach ($c in $issueComments) {
        $all += [pscustomobject]@{
            CreatedAt = [datetime]$c.created_at
            Type      = "Issue"
            Author    = $c.user.login
            Path      = $null
            Line      = $null
            Body      = $c.body
            Url       = $c.html_url
        }
    }

    foreach ($c in $inlineComments) {
        $all += [pscustomobject]@{
            CreatedAt = [datetime]$c.created_at
            Type      = "Inline"
            Author    = $c.user.login
            Path      = $c.path
            Line      = $c.line
            Body      = $c.body
            Url       = $c.html_url
        }
    }

    foreach ($r in $reviews) {
        if ($r.body) {
            $all += [pscustomobject]@{
                CreatedAt = if ($r.submitted_at) { [datetime]$r.submitted_at } else { Get-Date }
                Type      = "Review ($($r.state))"
                Author    = $r.user.login
                Path      = $null
                Line      = $null
                Body      = $r.body
                Url       = $r.html_url
            }
        }
    }

    $all |
      Sort-Object CreatedAt |
      Format-Table CreatedAt, Type, Author, Path, Line, Url, Body -Wrap
}
