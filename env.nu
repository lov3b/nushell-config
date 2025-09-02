$env.config = ($env.config
  | upsert edit_mode "vi"
  | upsert show_banner false
  | upsert history { max_size: 10_000, file_format: "sqlite" }
  | upsert completions { 
      case_sensitive: false
      quick: false
      partial: true
      algorithm: "fuzzy"
      sort: "smart"
  }
)
