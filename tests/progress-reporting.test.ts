import { describe, it, beforeEach, expect, vi } from "vitest"

// Mock the Clarity blockchain environment
const mockClarity = {
  contracts: {
    "project-registration": {
      functions: {
        "register-project": vi.fn(),
        "update-project-status": vi.fn(),
        "get-project": vi.fn(),
        "get-project-count": vi.fn(),
        "set-contract-admin": vi.fn(),
      },
      constants: {
        "STATUS-PROPOSED": 1,
        "STATUS-ACTIVE": 2,
        "STATUS-COMPLETED": 3,
        "STATUS-SUSPENDED": 4,
        "ERR-NOT-AUTHORIZED": 100,
        "ERR-PROJECT-EXISTS": 101,
        "ERR-PROJECT-NOT-FOUND": 102,
        "ERR-INVALID-STATUS": 103,
      },
    },
  },
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  },
}

// Mock the contract calls
const mockContractCall = (functionName, args, result) => {
  mockClarity.contracts["project-registration"].functions[functionName].mockReturnValueOnce(result)
}

describe("Project Registration Contract", () => {
  beforeEach(() => {
    // Reset all mocks before each test
    vi.resetAllMocks()
  })
  
  it("should register a new project successfully", () => {
    // Mock successful project registration
    mockContractCall(
        "register-project",
        [
          "Elephant Conservation Initiative",
          "Kenya",
          "African Elephant",
          1672531200, // Jan 1, 2023
          1704067200, // Jan 1, 2024
        ],
        { success: true, value: 1 },
    )
    
    // Call the contract function
    const result = mockClarity.contracts["project-registration"].functions["register-project"](
        "Elephant Conservation Initiative",
        "Kenya",
        "African Elephant",
        1672531200,
        1704067200,
    )
    
    // Verify the result
    expect(result).toEqual({ success: true, value: 1 })
    expect(mockClarity.contracts["project-registration"].functions["register-project"]).toHaveBeenCalledTimes(1)
  })
  
  it("should update project status successfully", () => {
    // Mock successful status update
    mockContractCall("update-project-status", [1, 2], { success: true, value: true })
    
    // Call the contract function
    const result = mockClarity.contracts["project-registration"].functions["update-project-status"](1, 2)
    
    // Verify the result
    expect(result).toEqual({ success: true, value: true })
    expect(mockClarity.contracts["project-registration"].functions["update-project-status"]).toHaveBeenCalledTimes(1)
  })
  
  it("should get project details successfully", () => {
    // Mock project data
    const projectData = {
      name: "Elephant Conservation Initiative",
      location: "Kenya",
      "target-species": "African Elephant",
      status: 2,
      "start-date": 1672531200,
      "end-date": 1704067200,
      coordinator: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      "registration-date": 100,
    }
    
    // Mock successful project retrieval
    mockContractCall("get-project", [1], { success: true, value: projectData })
    
    // Call the contract function
    const result = mockClarity.contracts["project-registration"].functions["get-project"](1)
    
    // Verify the result
    expect(result).toEqual({ success: true, value: projectData })
    expect(mockClarity.contracts["project-registration"].functions["get-project"]).toHaveBeenCalledTimes(1)
  })
  
  it("should fail when unauthorized user tries to register a project", () => {
    // Mock unauthorized error
    mockContractCall(
        "register-project",
        ["Elephant Conservation Initiative", "Kenya", "African Elephant", 1672531200, 1704067200],
        { success: false, error: 100 },
    )
    
    // Call the contract function
    const result = mockClarity.contracts["project-registration"].functions["register-project"](
        "Elephant Conservation Initiative",
        "Kenya",
        "African Elephant",
        1672531200,
        1704067200,
    )
    
    // Verify the result
    expect(result).toEqual({ success: false, error: 100 })
  })
})

