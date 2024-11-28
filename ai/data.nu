use sqlite.nu *

export def upsert-provider [--delete --action: closure] {
    $in | table-upsert --delete=$delete --action $action {
        table: provider
        pk: [name]
        default: {
            name: ''
            baseurl: 'https://'
            api_key: ''
            model_default: ''
            temp_default: 0.5
            temp_min: 0.0
            temp_max: 1.0
            org_id: ''
            project_id: ''
            active: 0
        }
    }
}

export def upsert-prompt [--delete --action: closure] {
    $in | table-upsert --action $action --delete=$delete {
        table: prompt
        pk: [name]
        default: {
            name: ''
            system: $env.OPENAI_PROMPT_TEMPLATE
            template: "```\n{}\n```"
            placeholder: '{}'
            description: ''
        }
        filter: {
            out: {
                placeholder: { $in | to yaml }
            }
            in: {
                placeholder: { $in | from yaml }
            }
        }
    }
}

export def upsert-function [--delete --action: closure] {
    $in | table-upsert --action $action --delete=$delete {
        table: function
        pk: [name]
        default: {
            name: ''
            description: ''
            parameters: {}
        }
        filter: {
            out: {
                parameters: { $in | to yaml }
            }
            in: {
                parameters: { $in | from yaml }
            }
        }
    }
}

export def seed [] {
    "
    - name: generating-prompts
      system: |-
        ### Goals
        The goal of this task is to generate a prompt that effectively communicates a specific message or sets a particular context for users. This prompt should be clear, concise, and tailored to the intended audience.
        # Role: You are a prompt generation assistant.

        ### Constraints
        - The prompt must include:
          - **Goals**: What do you want the user to achieve with this prompt?
          - **Constraints**: Any limitations or rules that need to be followed when creating the prompt.
          - **Attention**: What aspects of the prompt should users pay special attention to?
          - **OutputFormat**: How should the final prompt be formatted (e.g., Markdown)?
        - If it's for role-playing, the prompt should also include:
          - Role
          - Profile
          - Skills
          - Suggestions
        - If it's related to workflows, the prompt should also include:
          - Workflow
          - Initialization

        ### Attention
        Ensure that the generated prompt is user-friendly, informative, and engaging. It should clearly guide users on what to expect and how to respond appropriately.

        ### OutputFormat
        Use Markdown format for the output to make it easily readable and shareable.
        Output in {lang}
      template: '{}'
      placeholder: |-
        lang:
          en: English
          fr: French
          es: Spanish
          de: German
          zh: Chinese
          jp: Janpanese
          ko: Korean
      description: ''
    - name: polish
      system: |-
        #### Goals
        - To revise, edit, and polish the provided text without altering its original meaning.
        - To ensure the text is clear, concise, and well-organized.
        - To eliminate any redundant or verbose sections.

        #### Constraints
        - Maintain the original intent and key information.
        - Ensure the revised text is coherent and easy to read.
        - Remove unnecessary words and phrases.

        #### Attention
        - Focus on clarity and conciseness.
        - Pay attention to sentence structure and flow.
        - Ensure the text remains true to its original message.

        #### OutputFormat
        - Use Markdown format for the output to enhance readability.
        - Output in {lang}
      template: '{}'
      placeholder: |-
        lang:
          en: English
          fr: French
          es: Spanish
          de: German
          zh: Chinese
          jp: Janpanese
          ko: Korean
      description: ''
    - name: text-summary
      system: |-
        ### Text Summarization

        #### Goals
        - Generate a concise and coherent summary of the provided text.
        - Ensure that the summary captures the key points and main ideas of the original text.

        #### Constraints
        - The summary should be no more than 30% of the original text length.
        - Do not include any code blocks in the summary.
        - Avoid including website navigation or operational instructions.
        - Output in {lang}

        #### Attention
        - Focus on retaining the most important information and eliminating redundant details.
        - Maintain the original tone and style of the text as much as possible.

        #### OutputFormat
        - Use Markdown format for the output.
        - Ensure that the summary is well-structured and easy to read.

      template: '{}'
      placeholder: |-
        lang:
          en: English
          fr: French
          es: Spanish
          de: German
          zh: Chinese
          jp: Janpanese
          ko: Korean
      description: ''
    - name: json-to
      system: |-
        ### Prompt for Analyzing JSON Data and Generating Corresponding {lang} {object}

        #### Goals
        - Analyze the provided JSON data.
        - Generate a corresponding {lang} `{object}` that accurately represents the JSON structure.
        - Ensure the {lang} `{object}` is properly formatted and includes appropriate data types.

        #### Constraints
        - The JSON data will be provided as a string.
        - The generated {lang} `{object}` should use standard {lang} data types.
        - Handle nested structures and arrays appropriately.
        - Use `serde` for serialization and deserialization if necessary.
        - Do not explain.

        #### Attention
        - Pay special attention to the data types in the JSON, such as strings, numbers, booleans, arrays, and nested objects.
        - Ensure that optional fields are represented using `Option<T>`.

        #### OutputFormat
        Use Markdown format for the output to make it easily readable and shareable.

        ### Instructions
        1. Analyze the provided JSON data.
        2. Identify the data types and structure.
        3. Generate the corresponding {lang} `{object}`.
        4. Ensure the struct is properly formatted and includes appropriate data types.
      template: |-
        ```
        {}
        ```
      placeholder: |-
        lang:
          jsonschema: JsonSchema
          rs: Rust
          hs: Haskell
          ts: TypeScript
          py: Python pydantic
          nu: Nushell
          psql: PostgreSQL
          mysql: MySQL
          slite: Sqlite
        object:
          type: Type
          struct: Struct
          class: Class
          trait: Trait
          interface: Interface
          table: Table
      description: Analyze JSON content, converting it into
    - name: git-diff-summary
      system: |-
        ## Goals
        Extract commit messages from the `git diff` output

        ## Constraints
        summarize only the content changes within files, ignore changes in hashes, and generate a title based on these summaries.

        ## Attention
        - Lines starting with `+` indicate new lines added.
        - Lines starting with `-` indicate deleted lines.
        - Other lines are context and are not part of the current change being described.
        - Output in {lang}
      template: |-
        ```
        {}
        ```
      placeholder: |-
        lang:
          en: English
          fr: French
          es: Spanish
          de: German
          ru: Russian
          ar: Arabic
          zh: Chinese
          ja: Janpanese
          ko: Korean
      description: Summarize from git differences
    - name: programming-expert
      system: |-
        #### Goals
        - To provide accurate and helpful answers to user questions about {prog}
        - To offer concise examples where necessary to illustrate concepts or solutions.

        #### Constraints
        - Answers should be clear and concise.
        - Examples should be short and to the point.
        - Avoid overly complex explanations unless specifically requested by the user.

        #### Attention
        - Pay special attention to the user's level of expertise (beginner, intermediate, advanced) and tailor your responses accordingly.
        - Ensure that any code examples are well-commented and follow best practices in {prog}.

        #### Suggestions
        - When answering questions, start with a brief explanation of the concept or problem.
        - Follow up with a concise code example if applicable.
        - Provide links to relevant documentation or resources for further reading.

        #### OutputFormat
        - Use Markdown format for the output to make it easily readable and shareable.
        - Output in {lang}

      template: |-
        ```
        {}
        ```
      placeholder: |-
        lang:
          en: English
          fr: French
          es: Spanish
          de: German
          ru: Russian
          ar: Arabic
          zh: Chinese
          ja: Janpanese
          ko: Korean
        prog:
          rust: Rust
          javascript: Javascript
          python: Python
          nushell: Nushell
          bash: Bash
          sql: SQL
      description: api documents
    - name: debug
      system: |-
        # Role: {prog}
        ## Goals
        Analyze the causes of the error and provide suggestions for correction.
        ## Constraints
        - Output in {lang}
      template: |-
        ```
        {}
        ```
      placeholder: |-
        lang:
          en: English
          fr: French
          es: Spanish
          de: German
          ru: Russian
          ar: Arabic
          zh: Chinese
          ja: Janpanese
          ko: Korean
        prog:
          rust: You are a Rust language expert.
          javascript: You are a Javascript language expert.
          python: You are a Python language expert.
          nushell: You are a Nushell language expert.
      description: Programming language experts help you debug.
    - name: trans-to
      system: |-
        ## Goals
        Translate the following text into {lang}

        ## Constraints
        Only provide the translated content without explanations
        Do not enclose the translation result with quotes

        ## Attention
        Other instructions are additional requirements
        If it is in markdown format, do not translate code blocks
      template: |-
        {}
      placeholder: |-
        lang:
          en: English
          fr: French
          es: Spanish
          de: German
          ru: Russian
          ar: Arabic
          zh: Chinese
          ja: Janpanese
          ko: Korean
      description: Translation into the specified language
    - name: dictionary
      system: |-
        ### Prompt for Explaining Word Meanings, Usage, Synonyms, and Antonyms

        #### Goals
        - Provide a clear and comprehensive explanation of the given word(s).
        - Include the word's definition, usage in a sentence, and related synonyms and antonyms.
        - If multiple words are provided and separated by '|', explain the differences between them.

        #### Constraints
        - Use simple and clear language.
        - Ensure the explanation is accurate and concise.
        - Provide at least one example sentence for each word.
        - List at least two synonyms and two antonyms for each word, if applicable.
        - If explaining multiple words, highlight the key differences between them.

        #### Attention
        - Pay special attention to the nuances and contexts in which the words are used.
        - Make sure to clarify any potential confusion between similar words.
        - Use examples that are relatable and easy to understand.

        #### OutputFormat
        Use Markdown format to structure the response, making it easy to read and navigate.
        Output in {lang}

        ### Example Prompt

        #### Word: Happy | Joyful

        **Happy**
        - **Definition**: Feeling or showing pleasure or contentment.
        - **Usage**: She was happy to see her friends after a long time.
        - **Synonyms**: Cheerful, delighted
        - **Antonyms**: Sad, unhappy

        **Joyful**
        - **Definition**: Full of or causing great happiness.
        - **Usage**: The joyful children danced around the Christmas tree.
        - **Synonyms**: Blissful, elated
        - **Antonyms**: Miserable, sorrowful

        **Differences**
        - **Happy** is a general term for feeling good or satisfied, often used in everyday contexts.
        - **Joyful** is more intense and often associated with a deeper sense of happiness, typically used in more formal or celebratory contexts.
      template: |-
        ```{}```
      placeholder: |-
        lang:
          en: English
          fr: French
          es: Spanish
          de: German
          ru: Russian
          ar: Arabic
          zh: Chinese
          ja: Janpanese
          ko: Korean
      description: dictionary
    - name: report
      system: |
        ## Prompt: Summarize Your Daily Logs into a Work Progress Report

        ### Goals
        - Create a structured work progress report from your daily logs.
        - Organize tasks by different sections or categories.
        - Indicate the status of each task using the provided symbols.

        ### Constraints
        - Use `- [ ]` or `☐` to indicate uncompleted tasks.
        - Use `- [x]` or `🗹` to indicate completed tasks.
        - Ensure the report is clear and easy to follow.

        ### Attention
        - Pay attention to the logical structure of your report.
        - Group tasks under relevant headings to maintain clarity.
        - Use the symbols consistently to avoid confusion.

        ### Example Format

        ```markdown
        # Work Progress Report

        ## Date: [Insert Date]

        ### Project A
        - [x] Task 1: Description of the task
        - [ ] Task 2: Description of the task
        - [x] Task 3: Description of the task

        ### Project B
        - [ ] Task 1: Description of the task
        - [x] Task 2: Description of the task
        - [ ] Task 3: Description of the task

        ### Administrative Tasks
        - [x] Task 1: Description of the task
        - [ ] Task 2: Description of the task

        ### Notes
        - Any additional notes or comments about the day's work.
        ```

        ### Steps to Follow
        1. **Identify Projects and Tasks**: List all the projects and tasks you worked on today.
        2. **Organize by Sections**: Group tasks under relevant project headings.
        3. **Indicate Task Status**: Use `- [x]` or `🗹` for completed tasks and `- [ ]` or `☐` for uncom
        pleted tasks.
        4. **Add Notes**: Include any additional notes or comments at the end of the report.

        ### Tips
        - Keep your report concise and to the point.
        - Review your log entries to ensure accuracy.
        - Regularly update your report to track progress over time.
      template: '{}'
      placeholder: '{}'
      description: ''
    - name: generating-names
      system: |
        #### Goals
        Generate appropriate names based on the provided text. The names should be clear, concise, and unambiguous.

        #### Constraints
        - Only output names.
        - Each name should be on a separate line.
        - Use {format:} format.
        - Provide names in both English and {lang}.
        - Output multiple candidates if possible.

        #### Attention
        - Ensure the names are relevant to the input text.
        - Avoid any ambiguous or misleading names.
        - Use proper {format:} formatting ({format}).

        #### OutputFormat
        Lines

        ---

        ### Example Input
        Input Text: "快速发展的科技公司"

        ### Example Output
        fast growing tech company
        rapidly developing technology firm
        快速发展科技公司
        快速成长科技企业
      template: '{}'
      placeholder: |-
        lang:
          en: English
          fr: French
          es: Spanish
          de: German
          ru: Russian
          ar: Arabic
          zh: Chinese
          ja: Janpanese
          ko: Korean
        format:
          camel-case: The first word is in lowercase, and each subsequent word starts with an uppercase letter, with no spaces or hyphens between words.
          kebab-case: All letters are in lowercase, and words are separated by hyphens (`-`).
          pascal-case: Each word starts with an uppercase letter, including the first word, with no spaces or hyphens between words.
          screaming-snake-case: All letters are in uppercase, and words are separated by underscores (`_`).
          snake-case: All letters are in lowercase, and words are separated by underscores (`_`).
          title-case: The first letter of each word is capitalized, except for certain small words like articles, conjunctions, and prepositions (unless they are the first or last word in the title).
          usual: words with spaces.
      description: Naming suggestions
    - name: sql-query-analysis
      system: |-
          ### Prompt: SQL Query Analysis

          #### Goals
          - Analyze the provided SQL query from a business logic perspective.
          - Identify and describe the tables used in the query.
          - Explain the relationships between the tables.
          - Determine which fields in the query results come from which tables.
          - Identify the filtering conditions and their sources.

          #### Constraints
          - Provide a detailed analysis of the SQL query.
          - Focus on the business logic and how the query supports it.
          - Clearly explain the table relationships and data flow.
          - Ensure the analysis is accurate and comprehensive.

          #### Attention
          - Pay close attention to the structure of the SQL query.
          - Consider the business context and how the query fits into the overall system.
          - Be thorough in identifying and explaining the relationships between tables.
          - Clearly map out which fields in the result set come from which tables.
          - Identify and explain all filtering conditions and their sources.

          #### OutputFormat
          - Use Markdown format for the output.
          - Organize the analysis into clear sections for better readability.
          - Output in {lang}
      template: |-
        ```
        {}
        ```
      placeholder: |-
        lang:
          en: English
          fr: French
          es: Spanish
          de: German
          ru: Russian
          ar: Arabic
          zh: Chinese
          ja: Janpanese
          ko: Korean
      description: ''
    - name: sql-pre-aggregation
      system: |-
        ## Goals
        - Accept dimensions, metrics, and SQL queries.
        - Create materialized views based on the provided queries.
        - Provide an example of querying the materialized view.

        ## Constraints
        - Output valid PostgreSQL statements.
        - Do not consider refresh strategy-related issues.

        ## Attention
        - Group by dimensions:
          - If the dimension is a date/time type, use `time_bucket` to truncate it first.
        - Aggregate by metrics:
          - Use the `sum` aggregation function by default.
        - If filter conditions appear in the dimensions, remove them from the materialized view.

        ## Example Prompt

        ### Input
        - Dimensions: `date`, `product_id`
        - Metrics: `sales_amount`
        - SQL Query:
          ```sql
          SELECT date, product_id, SUM(sales_amount) AS total_sales
          FROM sales
          WHERE date >= '2023-01-01' AND date < '2024-01-01'
          GROUP BY date, product_id;
          ```

        ### Output
        1. **Create Materialized View:**
           ```sql
           CREATE MATERIALIZED VIEW sales_materialized_view AS
           SELECT
             time_bucket('1 day', date) AS date_bucket,
             product_id,
             SUM(sales_amount) AS total_sales
           FROM sales
           GROUP BY date_bucket, product_id;
           ```

        2. **Example Query on Materialized View:**
           ```sql
           SELECT date_bucket, product_id, total_sales
           FROM sales_materialized_view
           WHERE date_bucket >= '2023-01-01' AND date_bucket < '2024-01-01';
           ```

        ### Instructions
        - Ensure that the dimensions and metrics are correctly identified and used in the materialized view.
        - Use `time_bucket` for date/time dimensions to ensure proper truncation.
        - Apply the `sum` aggregation function to the metrics.
        - Remove any filter conditions that appear in the dimensions from the materialized view.
        - Provide a sample query to demonstrate how to use the materialized view.
      template: |-
        ```
        {}
        ```
      placeholder: '{}'
      description: matrialized view
    "
    | from yaml | each { $in | upsert-prompt }
    "
    - name: get_current_weather
      description: 'Get the current weather in a given location'
      parameters: |-
        type: object
        properties:
          location:
            type: string
            description: The city and state, e.g. San Francisco, CA
          unit:
            type: string
            enum:
            - celsius
            - fahrenheit
        required:
        - location
    "
    | from yaml | each { $in | upsert-function }
}

export def --env init [] {
    if 'OPENAI_PROMPT_TEMPLATE' not-in $env {
        $env.OPENAI_PROMPT_TEMPLATE = "_: |-
            # Role:
            ## Background:
            ## Attention:
            ## Profile:
            ## Constraints:
            ## Goals:
            ## Skills:
            ## Workflow:
            ## OutputFormat:
            ## Suggestions:
            ## Initialization:
            " | from yaml | get _
    }
    init-db OPENAI_STATE ([$nu.data-dir 'openai.db'] | path join) {|sqlx, Q|
        for s in [
            "CREATE TABLE IF NOT EXISTS provider (
                name TEXT PRIMARY KEY,
                baseurl TEXT NOT NULL,
                api_key TEXT DEFAULT '',
                model_default TEXT DEFAULT 'qwen2:1.5b',
                temp_default REAL DEFAULT 0.5,
                temp_min REAL DEFAULT 0,
                temp_max REAL NOT NULL,
                org_id TEXT DEFAULT '',
                project_id TEXT DEFAULT '',
                active BOOLEAN DEFAULT 0
            );"
            "CREATE INDEX idx_provider ON provider (name);"
            "CREATE INDEX idx_active ON provider (active);"
            "CREATE TABLE IF NOT EXISTS sessions (
                created TEXT,
                provider TEXT NOT NULL,
                model TEXT NOT NULL,
                temperature REAL NOT NULL
            );"
            "CREATE INDEX idx_sessions ON sessions (created);"
            "CREATE TABLE IF NOT EXISTS prompt (
                name TEXT PRIMARY KEY,
                system TEXT,
                template TEXT,
                placeholder TEXT NOT NULL DEFAULT '{}',
                description TEXT
            );"
            "CREATE INDEX idx_prompt ON prompt (name);"
            "CREATE TABLE IF NOT EXISTS messages (
                session_id TEXT,
                provider TEXT,
                model TEXT,
                role TEXT,
                content TEXT,
                token INTEGER,
                created TEXT,
                tag TEXT
            );"
            "CREATE INDEX idx_messages ON messages (session_id);"
            "CREATE TABLE IF NOT EXISTS function (
                name TEXT PRIMARY KEY,
                description TEXT,
                parameters TEXT,
                tag TEXT
            );"
            "CREATE INDEX idx_function ON function (name);"

            "CREATE TABLE IF NOT EXISTS scratch (
                id INTEGER PRIMARY KEY,
                type TEXT DEFAULT '',
                args TEXT DEFAULT '',
                content TEXT DEFAULT '',
                created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                function TEXT '',
                model TEXT ''
            );"

            "INSERT INTO provider (name, baseurl, model_default, temp_max, active) VALUES ('ollama', 'http://localhost:11434/v1', 'llama3.2:latest', 1, 1);"
        ] {
            do $sqlx $s
        }
        seed
    }
}

export def make-session [created] {
    for s in [
        $"INSERT INTO sessions \(created, provider, model, temperature\)
        SELECT (Q $created), name, model_default, temp_default
        FROM provider where active = 1 limit 1;"
    ] {
        sqlx $s
    }
}

export def session [] {
    sqlx $"select * from provider as p join sessions as s
        on p.name = s.provider where s.created = (Q $env.OPENAI_SESSION);"
    | first
}

export def record [session, provider, model, role, content, token, tag] {
    let n = date now | format date '%FT%H:%M:%S.%f'
    sqlx $"insert into messages \(session_id, provider, model, role, content, token, created, tag\)
        VALUES \((Q $session), (Q $provider), (Q $model), (Q $role), (Q $content), (Q $token), (Q $n), (Q $tag)\);"
}

export def messages [num = 10] {
    sqlx $"select role, content from messages where session_id = (Q $env.OPENAI_SESSION) and tag = '' order by created desc limit ($num)"
    | reverse
}
