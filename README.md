<h1>loggeer<h1/>
  
How to Use in this  Scripts:
Source the logger script:


```
source /path/to/logger.sh
Initialize the logger (optional arguments):
```

```

init_logger -L DEBUG -l "my_log_file.log" -v
Log messages using the appropriate log level:
```
```
log_info "This is an info message"
log_debug "This is a debug message"
log_warning "This is a warning message"
log_error "This is an error message"
log_critical "This is a critical message"
```
This should provide a flexible, reusable logging framework that can be easily imported into your other Bash scripts. Let me know if you'd like to make further adjustments!
