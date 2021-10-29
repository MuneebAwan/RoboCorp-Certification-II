# +
*** Settings ***
Documentation   This process is developed by Muneeb Tabassum for Robocorp Certification
...             This process will Order robots from robotsparebin industries
...             This process will save the receipt HTML in a pdf file
...             This process will take screenshot of robot and attach in pdf file
...             This process will zip the all reciepts
Library         RPA.Browser.Selenium
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.FileSystem
Library         RPA.HTTP
Library         RPA.Archive
Library         Dialogs
Library         RPA.Robocloud.Secrets
Library         RPA.core.notebook
Variables       variables.py

***Variables***
${Order_File_url}  https://robotsparebinindustries.com/orders.csv
${URL_website}  https://robotsparebinindustries.com/#/robot-order
${Orders_CSV_File}  orders.csv
${orders_file}    ${CURDIR}${/}${Orders_CSV_File}
${OUTPUT_DIR}  Reciepts
${Image_Dir}  ${CURDIR}${/}Images_robot
${PDF_Dir}  ${CURDIR}${/}PDF_reciepts
${zip_file}       ${CURDIR}${/}pdf_files_archived.zip


***Keywords***
Check Directory and File Exists
    # emtpy the directory and then check the pdf and image directory exist if not then create the directories
    Remove File  ${orders_file}
    ${reciept_folder}=  Does Directory Exist  ${PDF_Dir}
    log  ${reciept_folder}
    ${robots_folder}=  Does Directory Exist  ${Image_Dir}
    log  ${robots_folder}
    IF    '${reciept_folder}'=='False'
    Create Directory  ${PDF_Dir}
    ELSE
    log  ${PDF_Dir} Directory Already Exists
    END
    IF    '${robots_folder}'=='False'
    Create Directory  ${Image_Dir}
    ELSE
    log  ${Image_Dir} Directory Already Exists
    END
    
***Keywords***
Download the orders csv file
    # download the order csv file
    Download  ${Order_File_url}  ${Orders_CSV_File}
    
***Keywords***
Read data from the Orders CSV file
    # read the csv file and return the table.
    ${Table}  Read Table from Csv  ${Orders_CSV_File}  header=True
    Return From Keyword  ${Table}
***Keywords***
Close the browser
    Close Browser
    
***Keywords***
Exception handling
    # If there is any server error or exception then it will again click on the Order button.
    # if there is no server error then it will end the loop. 
    # after iteration there is again the server error then it will close the browser and end the process
    FOR  ${i}  IN RANGE  ${50}
            ${server_error}=  Is Element Visible  //div[@class="alert alert-danger"]  
            Run Keyword If  '${server_error}'=='True'  Click Button  //button[@id="order"] 
            Exit For Loop If  '${server_error}'=='False'       
        END
        Run Keyword If  '${server_error}'=='True'  Close the browser
***Keywords***
Open Order Processing Website
    # Open the Order processing website and maximize the browser
     Open Available Browser  ${URL_website}
     Maximize Browser Window
***Keywords***
Creating the Robots and Receipts
    [Arguments]  ${table}
    Open Order Processing Website
    FOR  ${row}  IN  @{table}  
        Form Filling  ${row}
        Exception handling
        ${orderid}=  Get Text  //*[@id="receipt"]/p[1]
        Set Local Variable  ${PDF_File}  ${orderid}.pdf
        Set Local Variable  ${Image_File}  ${orderid}.png
        Capture Element Screenshot      //*[@id="robot-preview-image"]    ${Image_Dir}${/}${Image_File}
        ${reciept_data}=  Get Element Attribute  //div[@id="receipt"]  outerHTML
        Sleep  5 seconds
        Creating the PDF files and Create pdf zip file  ${PDF_File}  ${Image_File}  ${reciept_data}
        Sleep  5 seconds
        # click on the next order after creating the receipts
        Click Button  //button[@id="order-another"]
    END
    Close the browser
    # Zip the pdf folder
    Archive Folder With ZIP     ${PDF_Dir}  ${zip_file}   recursive=True  include=*.pdf

***Keywords***
Form Filling
    # after reading the values from the csv file select the values from the head, body and leg
    # write the address and click on the preview button then click on order
    [Arguments]  ${row}
    # select the okay button on the loading of the page
    Wait Until Page Contains Element  //button[@class="btn btn-dark"]
    Click Button  //button[@class="btn btn-dark"]
    # select the head value
    Select From List By Value  //select[@name="head"]  ${row}[Head]
    # select the body value
    Click Element  //input[@value="${row}[Body]"]
    # input the leg value
    Input Text  //input[@placeholder="Enter the part number for the legs"]  ${row}[Legs]
    # input the address
    Input Text  //input[@name="address"]  ${row}[Address] 
    # Preview the robot
    Click Button  //button[@id="preview"]
    Sleep  5 seconds
    # click on order
    Click Button    //*[@id="order"]
    
***Keywords***
Creating the PDF files and Create pdf zip file
    [Arguments]  ${PDF_File}  ${Image_File}  ${reciept_data}
    Html To Pdf  ${reciept_data}  ${PDF_Dir}${/}${PDF_File}
    Add Watermark Image To Pdf  ${Image_Dir}${/}${Image_File}  ${PDF_Dir}${/}${PDF_File}  ${PDF_Dir}${/}${PDF_File}
    Close PDF           ${PDF_Dir}${/}${PDF_FILE}
    Open PDF        ${PDF_Dir}${/}${PDF_FILE}
    @{myfiles}=       Create List     ${Image_Dir}${/}${Image_File}
    Add Files To PDF    ${myfiles}    ${PDF_Dir}${/}${PDF_FILE}     ${True}
    Close PDF           ${PDF_Dir}${/}${PDF_FILE}

*** Tasks ***
Order Processing Process
    Check Directory and File Exists
    Download the orders csv file
    ${table}  Read data from the Orders CSV file
    log  ${Table}
    Creating the Robots and Receipts  ${table}
