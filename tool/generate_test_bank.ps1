param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\assets\test-bank')
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$bankId = '7c5fb5eb-975a-4f51-b3c3-118d3e45f001'
$work = Join-Path $OutputDirectory 'package-source'
$media = Join-Path $work 'media'
New-Item -ItemType Directory -Path $media -Force | Out-Null

function New-Question {
    param(
        [int]$Number,
        [string]$Type,
        [string]$Stem,
        [hashtable]$Options,
        [string[]]$Answers,
        [string]$Explanation,
        [string[]]$MediaFiles = @()
    )
    [ordered]@{
        question_id = ('7c5fb5eb-975a-4f51-b3c3-{0:d12}' -f $Number)
        external_id = ('TEST-{0:d3}' -f $Number)
        content_version = 1
        type = $Type
        stem = $Stem
        options = $Options
        answers = $Answers
        explanation = $Explanation
        knowledge_point = '应用闭环测试'
        source = '软件内置测试题（非正式考试资料）'
        year = '测试'
        chapter = if ($Number -le 5) { '基础交互' } elseif ($Number -le 10) { '判分与媒体' } else { '多选与相似题' }
        tags = @('测试题库', $Type)
        media = $MediaFiles
        scoring_rule = [ordered]@{
            single_score = 1.0
            multiple_score = 2.0
            partial_credit = $false
            partial_per_correct_option = 0.5
            wrong_option_makes_zero = $true
            unanswered_score = 0.0
        }
    }
}

$questions = @(
    New-Question 1 'single' '单选题应当允许用户选择几个答案？' @{A='只能选择一个';B='至少选择两个';C='必须全部选择';D='不能选择'} @('A') '单选题正式提交前只能保留一个有效选项。'
    New-Question 2 'single' '试卷尚未交卷时，应用是否应显示正确答案？' @{A='始终显示';B='只显示选项，不显示答案';C='随机显示';D='联网时显示'} @('B') '交卷前数据层和界面均不应泄露答案。'
    New-Question 3 'single' '断网答题时，作答首先写入哪里？' @{A='云端';B='剪贴板';C='本地 SQLite 事务';D='临时网页'} @('C') '本地 SQLite 是第一落点，云同步随后进行。'
    New-Question 4 'single' '同一 event_id 和完全相同内容再次提交，应如何处理？' @{A='重复计错';B='作为幂等重放';C='删除原事件';D='生成新题'} @('B') '相同事件与相同载荷不得重复影响统计。'
    New-Question 5 'single' '试卷中的未作答题交卷后，其学习状态应当怎样？' @{A='保持未见';B='标为答错';C='标为掌握';D='自动排除'} @('A') '未作答参加试卷统计，但不生成正式作答事件。'
    New-Question 6 'single' '观察示意图后，哪条路径表示本地优先？' @{A='作答→云端→本地';B='作答→本地→同步队列';C='作答→丢弃';D='云端→作答'} @('B') '图示用于验证媒体随题库包导入。' @('media/flow.png')
    New-Question 7 'single' '图中的警示符号用于本测试包的什么目的？' @{A='验证媒体存在性';B='联网登录';C='修改系统设置';D='生成答案'} @('A') '只用于验证图片题的导入、复制和展示。' @('media/sign.png')
    New-Question 8 'single' "根据下表，状态 wrong 的中文含义是？`n`n| state | 含义 |`n|---|---|`n| unseen | 未见 |`n| wrong | 当前错题 |`n| mastered | 已掌握 |" @{A='未见';B='当前错题';C='已掌握';D='已排除'} @('B') '用于验证 Markdown 表格题干保持可读。'
    New-Question 9 'single' '建议完成时长超过后，软件应如何处理？' @{A='自动交卷';B='清空选择';C='提示超时但继续答题';D='关闭软件'} @('C') '建议时长不是强制倒计时。'
    New-Question 10 'single' '完成试卷历史应保存什么题目内容？' @{A='只保存题号';B='保存提交时题目快照';C='总是读取最新版';D='只保存得分'} @('B') '题库更新不得改变历史试卷。'
    New-Question 11 'multiple' '下列哪些属于独立的题目标记？' @{A='收藏';B='不确定';C='排除';D='当前对错状态'} @('A','B','C') '收藏、不确定、排除与对错状态分别保存。'
    New-Question 12 'multiple' '下列哪些内容属于完整错题导出？' @{A='题干和选项';B='用户选择';C='正确答案与解析';D='考点和历史'} @('A','B','C','D') '错题材料应可脱离软件独立阅读。'
    New-Question 13 'multiple' '下列哪些场景必须保留本地数据？' @{A='网络失败';B='应用退出';C='同步重试';D='题库更新'} @('A','B','C','D') '本地记录不能因云端或题库变化丢失。'
    New-Question 14 'multiple' '相似题 A：哪些选项是元音字母？' @{A='A';B='B';C='E';D='G'} @('A','C') '用于验证相似题干不被错误合并，答案为 A、C。'
    New-Question 15 'multiple' '相似题 B：哪些选项是辅音字母？' @{A='A';B='B';C='E';D='G'} @('B','D') '用于验证相似题干不被错误合并，答案为 B、D。'
)

$jsonLines = $questions | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 12 }
$questionsPath = Join-Path $work 'questions.jsonl'
[System.IO.File]::WriteAllLines($questionsPath, $jsonLines, $utf8NoBom)

Add-Type -AssemblyName System.Drawing.Common
function New-DiagramPng([string]$Path, [string]$Title, [string]$Text, [System.Drawing.Color]$Color) {
    $bitmap = [System.Drawing.Bitmap]::new(720, 240)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear([System.Drawing.Color]::White)
        $pen = [System.Drawing.Pen]::new($Color, 8)
        $brush = [System.Drawing.SolidBrush]::new($Color)
        $titleFont = [System.Drawing.Font]::new('Microsoft YaHei UI', 26, [System.Drawing.FontStyle]::Bold)
        $textFont = [System.Drawing.Font]::new('Microsoft YaHei UI', 18)
        try {
            $graphics.DrawRectangle($pen, 12, 12, 696, 216)
            $graphics.DrawString($Title, $titleFont, $brush, 40, 42)
            $graphics.DrawString($Text, $textFont, [System.Drawing.Brushes]::Black, 40, 120)
            $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $pen.Dispose(); $brush.Dispose(); $titleFont.Dispose(); $textFont.Dispose()
        }
    } finally {
        $graphics.Dispose(); $bitmap.Dispose()
    }
}
New-DiagramPng (Join-Path $media 'flow.png') '本地优先' '作答 → SQLite 事务 → outbox → 云端' ([System.Drawing.Color]::FromArgb(34, 96, 153))
New-DiagramPng (Join-Path $media 'sign.png') '测试媒体' '此图仅用于验证题库媒体闭环' ([System.Drawing.Color]::FromArgb(196, 92, 24))

$questionsHash = (Get-FileHash -LiteralPath $questionsPath -Algorithm SHA256).Hash.ToLowerInvariant()
$mediaManifest = Get-ChildItem -LiteralPath $media -File | Sort-Object Name | ForEach-Object {
    [ordered]@{
        path = 'media/' + $_.Name
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        size = $_.Length
    }
}
$manifest = [ordered]@{
    schema_version = 1
    bank_id = $bankId
    name = '个人刷题软件 15 题测试库'
    subject = '软件闭环测试'
    description = '10 道单选、5 道多选；含 2 道图片题、1 道表格题和 2 道相似题。'
    content_version = 1
    question_count = 15
    created_at_utc = '2026-08-19T00:00:00Z'
    questions_sha256 = $questionsHash
    media_manifest = @($mediaManifest)
}
[System.IO.File]::WriteAllText((Join-Path $work 'manifest.json'), ($manifest | ConvertTo-Json -Depth 12), $utf8NoBom)

$zipPath = Join-Path $OutputDirectory 'test-bank.zip'
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -Path (Join-Path $work '*') -DestinationPath $zipPath -CompressionLevel Optimal
[ordered]@{
    zip = $zipPath
    questions = $questions.Count
    singles = @($questions | Where-Object type -eq 'single').Count
    multiples = @($questions | Where-Object type -eq 'multiple').Count
    sha256 = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
} | ConvertTo-Json
