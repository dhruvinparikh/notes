pragma solidity ^0.5.8;

contract DICCertification{
    uint constant private MINIMUM_GPA_REQUIRED = 250;

    struct Student {
        uint personNumber;

        uint prereq115;
        uint prereq116;

        uint core250;
        uint core486;
        uint core487;

        uint domainSpecificCourse;
        uint domainSpecificGrade;
        uint capstoneCourse;
        uint capstoneGrade;

        // uint gpa;                // Not required anymore as GPA is calculated everytime check is called.
    }

    mapping(address => Student) public registeredStudents;

    event preRequisiteSatisified(uint personNumber);
    event coreCoursesSatisfied(uint personNumber);
    event GPARequirementSatisfied(uint personNumber);
    event projectRequirementSatisfied(uint personNumber);
    event domainRequirementSatisfied(uint personNumber);
    event GPA(uint result);

//----------------------------------------------------------------------------------------------
// Modifiers
//----------------------------------------------------------------------------------------------
    modifier checkStudent(uint personNumber) {
        require(registeredStudents[msg.sender].personNumber == 0, "Student has already registered");
        _;
    }

    modifier validStudent(){
        require(registeredStudents[msg.sender].personNumber > 0, "Invalid student");
        _;
    }

//----------------------------------------------------------------------------------------------
// Functions
//----------------------------------------------------------------------------------------------
    function registerStudent(uint personNumber) public checkStudent(personNumber) {
        registeredStudents[msg.sender].personNumber = personNumber;
   }

    function loginStudent(uint personNumber) public view returns (bool){
        if(registeredStudents[msg.sender].personNumber == personNumber){
            return true;
        }else{
            return false;
        }
    }

    function addPreRequisiteCourse(uint courseNumber, uint grade) public validStudent {

        if(courseNumber == 115) {
            registeredStudents[msg.sender].prereq115 = grade;
        }
        else if(courseNumber == 116) {
            registeredStudents[msg.sender].prereq116 = grade;
        }
        else {
            revert("Invalid course information provided");
        }
    }

    function addCoreCourse(uint courseNumber, uint grade) public validStudent {

        if(courseNumber == 250) {
            registeredStudents[msg.sender].core250 = grade;
        }
        else if(courseNumber == 486) {
            registeredStudents[msg.sender].core486 = grade;
        }
        else if(courseNumber == 487) {
            registeredStudents[msg.sender].core487 = grade;
        }
        else {
            revert("Invalid course information provided");
        }
    }

    function addDomainSpecificCourse(uint courseNumber, uint grade) public validStudent {

        // courseNumber is uint hence negetive number will underflow.
        require(courseNumber < 1000, "Invalid course information provided");
        registeredStudents[msg.sender].domainSpecificCourse = courseNumber;
        registeredStudents[msg.sender].domainSpecificGrade = grade;

    }

    function addCapstoneCourse(uint courseNumber, uint grade) public validStudent {

        // courseNumber is uint hence negetive number will underflow.
        require(courseNumber < 1000, "Invalid course information provided");
        registeredStudents[msg.sender].capstoneCourse = courseNumber;
        registeredStudents[msg.sender].capstoneGrade = grade;

    }

    function checkEligibility(uint personNumber) public validStudent returns(bool) {

        bool preRequisitesSatisfied = false;
        bool coreSatisfied = false;
        bool domainSpecificSatisfied = false;
        bool capstoneSatisfied = false;
        bool gradeSatisfied = false;
        uint totalGPA = 0;

        // all grades > FAIL_GRADE signify valid courses without fail grades.
        if(registeredStudents[msg.sender].prereq115 > 0 &&
        registeredStudents[msg.sender].prereq116 > 0) {

            preRequisitesSatisfied = true;
            emit preRequisiteSatisified(personNumber);
            totalGPA += registeredStudents[msg.sender].prereq115 + registeredStudents[msg.sender].prereq116;
        }

        if(registeredStudents[msg.sender].core250 > 0 &&
        registeredStudents[msg.sender].core486 > 0 &&
        registeredStudents[msg.sender].core487 > 0) {

            coreSatisfied = true;
            emit coreCoursesSatisfied(personNumber);

            totalGPA += registeredStudents[msg.sender].core250 + registeredStudents[msg.sender].core486 +
                        registeredStudents[msg.sender].core487;
        }

        // domainSpecificGrade > 0 signifies valid course.
        if(registeredStudents[msg.sender].domainSpecificGrade > 0){
            domainSpecificSatisfied = true;
            emit domainRequirementSatisfied(personNumber);
            totalGPA += registeredStudents[msg.sender].domainSpecificGrade;
        }

        // capstoneGrade > 0 signifies valid course.
        if(registeredStudents[msg.sender].capstoneGrade > 0){
            capstoneSatisfied = true;
            emit projectRequirementSatisfied(personNumber);
            totalGPA += registeredStudents[msg.sender].capstoneGrade;
        }

        if(preRequisitesSatisfied && coreSatisfied && domainSpecificSatisfied && capstoneSatisfied) {

            // totalGPA = registeredStudents[msg.sender].prereq115 + registeredStudents[msg.sender].prereq116 +
            //            registeredStudents[msg.sender].core250 + registeredStudents[msg.sender].core486 +
            //            registeredStudents[msg.sender].core487 + registeredStudents[msg.sender].domainSpecificGrade +
            //            registeredStudents[msg.sender].capstoneGrade;

            // Final GPA calculated.
            totalGPA /= 7;

            // GPA event can be emitted regardless of completion as this serves as a record.
            emit GPA(totalGPA);

            if(totalGPA >= MINIMUM_GPA_REQUIRED) {
                gradeSatisfied = true;
                emit GPARequirementSatisfied(personNumber);
            }
        }

        // return preRequisitesSatisfied && coreSatisfied && domainSpecificSatisfied && capstoneSatisfied && gradeSatisfied;
        // gradeSatisfied requires all previous stages to pass. Hence above line is commented and replaced by below line.
        return gradeSatisfied;
    }

    function destroy() public {
        selfdestruct(msg.sender);
    }

}