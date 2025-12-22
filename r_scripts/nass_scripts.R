store_nass_api_key <- function(api_key, overwrite = FALSE) {
  # Get path to .Renviron file
  renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")

  # Read existing .Renviron if it exists
  if (file.exists(renviron_path)) {
    renviron_lines <- readLines(renviron_path)

    # Check if NASS_API_KEY already exists
    key_exists <- any(grepl("^NASS_API_KEY=", renviron_lines))

    if (key_exists && !overwrite) {
      stop(
        "NASS_API_KEY already exists in .Renviron. ",
        "Set overwrite = TRUE to replace it."
      )
    }

    # Remove existing NASS_API_KEY line if overwriting
    if (key_exists && overwrite) {
      renviron_lines <- renviron_lines[!grepl("^NASS_API_KEY=", renviron_lines)]
    }
  } else {
    renviron_lines <- character(0)
  }

  # Add new NASS_API_KEY
  renviron_lines <- c(renviron_lines, paste0("NASS_API_KEY=", api_key))

  # Write back to .Renviron
  writeLines(renviron_lines, renviron_path)

  message(
    "NASS_API_KEY stored in .Renviron\n",
    "Restart R session for changes to take effect, or run:\n",
    "  readRenviron('~/.Renviron')"
  )

  invisible(TRUE)
}


get_nass_data <- function(
  api_key = Sys.getenv("NASS_API_KEY"),
  source_desc = NULL,
  sector_desc = NULL,
  group_desc = NULL,
  commodity_desc = NULL,
  class_desc = NULL,
  statisticcat_desc = NULL,
  state_alpha = NULL,
  state_fips_code = NULL,
  agg_level_desc = NULL,
  domain_desc = NULL,
  domaincat_desc = NULL,
  unit_desc = NULL,
  year = NULL,
  format = "CSV"
) {
  # Validate API key
  if (is.null(api_key) || api_key == "") {
    stop(
      "API key is missing. Please provide an API key or set NASS_API_KEY ",
      "environment variable using store_nass_api_key()."
    )
  }

  # Build the base request
  req <- request("https://quickstats.nass.usda.gov/api/api_GET/") |>
    req_url_query(
      key = api_key,
      format = format
    )

  # Add optional parameters if provided
  if (!is.null(source_desc)) {
    req <- req |> req_url_query(source_desc = source_desc)
  }
  if (!is.null(sector_desc)) {
    req <- req |> req_url_query(sector_desc = sector_desc)
  }
  if (!is.null(group_desc)) {
    req <- req |> req_url_query(group_desc = group_desc)
  }
  if (!is.null(commodity_desc)) {
    req <- req |> req_url_query(commodity_desc = commodity_desc)
  }
  if (!is.null(class_desc)) {
    req <- req |> req_url_query(class_desc = class_desc)
  }
  if (!is.null(statisticcat_desc)) {
    req <- req |> req_url_query(statisticcat_desc = statisticcat_desc)
  }
  if (!is.null(state_alpha)) {
    req <- req |> req_url_query(state_alpha = state_alpha)
  }
  if (!is.null(state_fips_code)) {
    req <- req |> req_url_query(state_fips_code = state_fips_code)
  }
  if (!is.null(agg_level_desc)) {
    req <- req |> req_url_query(agg_level_desc = agg_level_desc)
  }
  if (!is.null(domain_desc)) {
    req <- req |> req_url_query(domain_desc = domain_desc)
  }
  if (!is.null(domaincat_desc)) {
    req <- req |> req_url_query(domaincat_desc = domaincat_desc)
  }
  if (!is.null(unit_desc)) {
    req <- req |> req_url_query(unit_desc = unit_desc)
  }
  if (!is.null(year)) {
    req <- req |> req_url_query(year = year)
  }

  # Print the full request URL for debugging
  message("Request URL: ", req$url)

  # Perform the request with error handling
  resp <- tryCatch(
    {
      req |>
        req_retry(max_tries = 3) |>
        req_error(
          body = function(resp) {
            body_text <- resp_body_string(resp)

            # Provide helpful error messages based on status code
            error_msg <- switch(
              as.character(resp_status(resp)),
              "400" = paste0(
                "HTTP 400 Bad Request - Invalid parameters.\n",
                "This usually means one or more parameter values are incorrect.\n",
                "Common issues:\n",
                "  - Typos in parameter values (check exact spelling/capitalization)\n",
                "  - Invalid combinations of parameters\n",
                "  - Using 'source' instead of 'source_desc'\n",
                "\nRequest URL: ",
                req$url,
                "\n",
                "\nAPI Response: ",
                body_text
              ),
              "401" = "HTTP 401 Unauthorized - Invalid API key",
              "413" = paste0(
                "HTTP 413 Payload Too Large - Query returned too many records.\n",
                "Try adding more filters (year, state, commodity, etc.)"
              ),
              paste0("HTTP ", resp_status(resp), " - ", resp_status_desc(resp))
            )

            error_msg
          }
        ) |>
        req_perform()
    },
    error = function(e) {
      stop(e$message, call. = FALSE)
    }
  )

  # Parse response based on format
  if (format == "CSV") {
    result <- resp |>
      resp_body_string() |>
      readr::read_csv(show_col_types = FALSE)

    # Check if result is empty
    if (nrow(result) == 0) {
      warning(
        "Query returned 0 rows. Try relaxing your filters or checking parameter values.\n",
        "Request URL: ",
        req$url
      )
    } else {
      message("Successfully retrieved ", nrow(result), " rows")
    }

    result
  } else if (format == "JSON") {
    resp |> resp_body_json()
  } else {
    resp |> resp_body_string()
  }
}

get_nass_param_values <- function(
  param,
  api_key = Sys.getenv("NASS_API_KEY"),
  source_desc = NULL,
  sector_desc = NULL,
  group_desc = NULL,
  commodity_desc = NULL,
  class_desc = NULL,
  statisticcat_desc = NULL,
  state_alpha = NULL,
  state_fips_code = NULL,
  agg_level_desc = NULL,
  domain_desc = NULL,
  domaincat_desc = NULL,
  unit_desc = NULL,
  year = NULL
) {
  # Validate API key
  if (is.null(api_key) || api_key == "") {
    stop(
      "API key is missing. Please provide an API key or set NASS_API_KEY ",
      "environment variable using store_nass_api_key()."
    )
  }

  # Validate param is provided
  if (missing(param) || is.null(param)) {
    stop(
      "Parameter 'param' is required. ",
      "Valid values include: source_desc, sector_desc, group_desc, ",
      "commodity_desc, class_desc, statisticcat_desc, domain_desc, domaincat_desc, ",
      "agg_level_desc, state_alpha, state_fips_code, county_name, year, etc."
    )
  }

  # Build the base request
  req <- request("https://quickstats.nass.usda.gov/api/get_param_values/") |>
    req_url_query(
      key = api_key,
      param = param
    )

  # Add optional filter parameters if provided
  if (!is.null(source_desc)) {
    req <- req |> req_url_query(source_desc = source_desc)
  }
  if (!is.null(sector_desc)) {
    req <- req |> req_url_query(sector_desc = sector_desc)
  }
  if (!is.null(group_desc)) {
    req <- req |> req_url_query(group_desc = group_desc)
  }
  if (!is.null(commodity_desc)) {
    req <- req |> req_url_query(commodity_desc = commodity_desc)
  }
  if (!is.null(class_desc)) {
    req <- req |> req_url_query(class_desc = class_desc)
  }
  if (!is.null(statisticcat_desc)) {
    req <- req |> req_url_query(statisticcat_desc = statisticcat_desc)
  }
  if (!is.null(state_alpha)) {
    req <- req |> req_url_query(state_alpha = state_alpha)
  }
  if (!is.null(state_fips_code)) {
    req <- req |> req_url_query(state_fips_code = state_fips_code)
  }
  if (!is.null(agg_level_desc)) {
    req <- req |> req_url_query(agg_level_desc = agg_level_desc)
  }
  if (!is.null(domain_desc)) {
    req <- req |> req_url_query(domain_desc = domain_desc)
  }
  if (!is.null(domaincat_desc)) {
    req <- req |> req_url_query(domaincat_desc = domaincat_desc)
  }
  if (!is.null(unit_desc)) {
    req <- req |> req_url_query(unit_desc = unit_desc)
  }
  if (!is.null(year)) {
    req <- req |> req_url_query(year = year)
  }

  # Print the full request URL for debugging
  message("Request URL: ", req$url)

  # Perform the request with error handling
  resp <- tryCatch(
    {
      req |>
        req_retry(max_tries = 3) |>
        req_error(
          body = function(resp) {
            body_text <- resp_body_string(resp)

            error_msg <- switch(
              as.character(resp_status(resp)),
              "400" = paste0(
                "HTTP 400 Bad Request - Invalid parameter name or filters.\n",
                "Check that 'param' is a valid parameter name.\n",
                "\nRequest URL: ",
                req$url,
                "\n",
                "\nAPI Response: ",
                body_text
              ),
              "401" = "HTTP 401 Unauthorized - Invalid API key",
              paste0("HTTP ", resp_status(resp), " - ", resp_status_desc(resp))
            )

            error_msg
          }
        ) |>
        req_perform()
    },
    error = function(e) {
      stop(e$message, call. = FALSE)
    }
  )

  # Parse response as JSON and extract values
  result <- resp |> resp_body_json()

  # The API returns a list with the parameter values
  if (length(result) == 0) {
    warning(
      "Query returned 0 parameter values. ",
      "Try different filters or check parameter name.\n",
      "Request URL: ",
      req$url
    )
    return(character(0))
  }

  # Extract values from nested list structure
  values <- unlist(result)

  message("Retrieved ", length(values), " unique values for '", param, "'")

  values
}
