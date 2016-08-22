numq <- 23
numd <- 4
numd1q <- 4
numd2q <- 12
numd3q <- 3
numd4q <- 4

domain.code <- data.frame(domain = c(rep(1, numd1q), rep(2,numd2q), rep(3,numd3q), rep(4,numd4q)), question = 1:numq)

question.names <- data.frame(
  question_name = c(
    question = c(1:23), 
    "Models enthusiasm for teaching and learning",
    "Identifies and completes tasks without being asked",
    "Accepts constructive feedback",
    "Takes risks and tries new strategies",
    "Uses tact and discretion",
    "Displays self-confidence, poise and flexibility",
    "Develops `withitness'",
    "Interacts effectively with coworkers and professionals",
    "Develops cooperative, professional relationships with families",
    "Demonstrates professional behavior",
    "Demonstrates the physical and emotional capacity to handle the demands of teaching",
    "Displays a commitment to social justice",
    "Reflects understanding and adherence to legal and ethical responsibilities",
    "Writes learning targets that address procedural and/or conceptual development of content",
    "Aligns learning with standards",
    "Provides assessment evidence aligned with learning targets",
    "Adapts assessment and instruction based on IEPs and 504 plans",
    "Identifies language demands and classroom support for such demands",
    "Uses knowledge of students to personalize the learning targets and tasks",
    "Plans for instructional tasks account for students' prior learning and/or cultural/community assets",
    "Integrates across curriculum areas as appropriate",
    "Employs strategies for culturally responsive and differentiated instruction",
    "Plans for collaboration with families as appropriate"))
domain.names <- data.frame(
  domain = c(1:4), 
  domain_name = c("Interpersonal and professional behavior",
                  "Planning",
                  "Instruction",
                  "Assessment"))

